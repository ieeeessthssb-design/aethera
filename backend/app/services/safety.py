"""Safety rules for the Aethera assistant (task 34).

Deterministic, offline, no dependencies. Runs BEFORE any answer is generated
(stub, RAG or LLM), so an LLM can never be the only barrier.

Verdicts, strongest first:
  EMERGENCY         poisoning / exposure -> no agronomy answer, urgent medical wording
  PESTICIDE_DOSAGE  dose, mixing ratio, concentration, spray schedule -> REFUSE
  PESTICIDE_TOPIC   any other pesticide question -> REFUSE product advice + escalate
  FERTILIZER_DOSAGE exact fertilizer rates -> REFUSE + escalate (needs soil analysis)
  DISEASE           disease / pest diagnosis in text -> answer cautiously + escalate
  UNCLEAR           empty, too short or nonsense -> ask to rephrase + escalate
  OK                nothing special

REFUSE verdicts replace the answer. ESCALATE verdicts keep the answer but add
"check with an expert" wording and create an expert case.
The keyword lists are a first version: have Derja speakers extend them.
"""
import re
import unicodedata
from dataclasses import dataclass
from enum import Enum
from typing import Dict, Optional

# Verify before the jury demo and edit if needed.
EMERGENCY_NUMBER = "190"  # SAMU Tunisia


class Category(str, Enum):
    OK = "ok"
    EMERGENCY = "emergency"
    PESTICIDE_DOSAGE = "pesticide_dosage"
    PESTICIDE_TOPIC = "pesticide_topic"
    FERTILIZER_DOSAGE = "fertilizer_dosage"
    DISEASE = "disease"
    UNCLEAR = "unclear"


@dataclass(frozen=True)
class Verdict:
    category: Category
    refuse: bool          # True -> do not answer the question itself
    escalate: bool        # True -> create an expert case
    language: str         # ar | fr | en
    reply: Optional[str] = None  # full replacement answer when refuse is True


# ---------------------------------------------------------------- text helpers

_ARABIC_DIACRITICS = re.compile("[\u064b-\u065f\u0670\u0640]")  # harakat + tatweel


def normalize(text: str) -> str:
    text = unicodedata.normalize("NFKC", text or "").lower()
    text = _ARABIC_DIACRITICS.sub("", text)
    text = re.sub("[\u0623\u0625\u0622]", "\u0627", text)  # alef variants -> alef
    text = text.replace("\u0649", "\u064a").replace("\u0629", "\u0647")  # alef maqsura, ta marbuta
    return re.sub(r"\s+", " ", text).strip()


def detect_language(text: str) -> str:
    if re.search("[\u0600-\u06ff]", text or ""):
        return "ar"
    t = normalize(text)
    french = r"\b(le|la|les|un|une|des|du|de|je|mon|ma|mes|comment|combien|quel|quelle|pour|avec|dois|faut|est|sont|traitement|produit|traiter|quand|dans|sur|que|qui|arroser|irriguer|mes|tes|ses|nos|vos)\b"
    if re.search("[àâçéèêëîïôùûüÿœ]", t) or len(re.findall(french, t)) >= 2:
        return "fr"
    return "en"


def _has(text: str, terms) -> bool:
    for term in terms:
        term = normalize(term)
        if re.search("[\u0600-\u06ff]", term):
            if len(term) <= 3:  # short Arabic roots: whole word, optional attached prefix
                if re.search("(?<![\u0600-\u06ff])(?:\u0627\u0644|[\u0648\u0641\u0628\u0644])?(?:\u0627\u0644)?"
                             + re.escape(term) + "(?![\u0600-\u06ff])", text):
                    return True
            elif term in text:  # longer Arabic terms: substring (prefixes are attached to words)
                return True
        elif re.search(r"(?<![a-z0-9])" + re.escape(term) + r"(?![a-z0-9])", text):
            return True
    return False


# ------------------------------------------------------------------ vocabulary

PESTICIDE_TERMS = [
    "pesticide", "pesticides", "herbicide", "fungicide", "fongicide", "fongicides", "insecticide", "acaricide",
    "nematicide", "rodenticide", "molluscicide", "agrochemical", "weed killer", "weedkiller",
    "spray", "spraying", "phytosanitaire", "phytosanitaires", "produit phyto", "pulveriser",
    "pulverisation", "traitement chimique", "bouillie", "insecticides",
    "glyphosate", "mancozeb", "imidacloprid", "deltamethrin", "chlorpyrifos", "cypermethrin",
    "copper sulfate", "sulfate de cuivre", "bouillie bordelaise", "roundup",
    "مبيد", "مبيدات", "مبيد حشري", "مبيد فطري", "مبيد اعشاب", "رش", "الرش", "رشيت", "نرش",
    "جلايفوسات", "سم الفئران",
    "mbid", "mobid", "mbidat",  # Arabizi, to be reviewed with Derja speakers
]

DOSAGE_TERMS = [
    "dose", "doses", "dosage", "dosing", "how much", "how many", "ratio", "concentration",
    "dilute", "dilution", "mix", "mixing", "mixture", "tank mix", "per liter", "per litre",
    "per hectare", "per ha", "ml", "g/l", "ml/l", "l/ha", "kg/ha", "gram", "grams", "cc",
    "how often", "how many times", "schedule", "frequency", "interval", "days before harvest",
    "combien", "dosage", "dose", "doser", "melange", "melanger", "diluer", "dilution",
    "concentration", "quantite", "par litre", "par hectare", "a quelle frequence",
    "frequence", "intervalle", "delai avant recolte", "proportion", "cuillere",
    "جرعه", "جرعة", "كميه", "كمية", "كم", "قداش", "قدّاش", "شحال", "نسبه", "نسبة", "تركيز",
    "خلط", "مزج", "اخلط", "نخلط", "تخفيف", "خفف", "غرام", "جرام", "لتر", "مل", "ملل",
    "هكتار", "كم مره", "كم مرة", "كل كم", "عدد المرات", "مواعيد", "موعد", "ركب", "نحط", "نحطو",
    "نزيد", "احط", "اضيف", "نضيف", "علاش نرش",
    "9addech", "9eddech", "chhal", "kdech",
]

POISONING_TERMS = [
    "poisoned", "poisoning", "swallowed", "drank", "ingested", "inhaled", "intoxicated",
    "child drank", "my child", "my son", "my daughter", "animal died", "animals died",
    "livestock died", "sheep died", "cow died", "dog died", "bee", "bees died",
    "intoxique", "intoxication", "empoisonne", "empoisonnement", "avale", "ingere", "inhale",
    "mon enfant", "mon fils", "ma fille", "animal est mort", "betail mort", "mouton mort",
    "تسمم", "تسممت", "تسمّم", "بلع", "شرب", "شربت", "ابتلع", "استنشق", "استنشاق", "ماتت", "مات",
    "ولدي", "طفلي", "بنتي", "ابني",
]

POISON_CONTEXT_TERMS = ["pesticide", "pesticides", "herbicide", "fungicide", "insecticide", "chemical",
                        "produit", "poison", "toxique", "toxic", "مبيد", "مبيدات", "سم", "كيماوي", "كيميائي",
                        "رش", "دواء", "spray"]

FERTILIZER_TERMS = ["fertilizer", "fertiliser", "fertilizers", "engrais", "npk", "urea", "uree", "nitrate",
                    "سماد", "تسميد", "اسمده", "يوريا", "ازوت", "آزوت"]

DISEASE_TERMS = [
    "disease", "diseased", "blight", "mildew", "mold", "mould", "rot", "rust", "fungus", "fungal",
    "virus", "wilt", "wilting", "spots", "spot on", "pest", "pests", "aphid", "aphids",
    "whitefly", "mite", "mites", "caterpillar", "insects", "infected", "infection", "dying",
    "maladie", "malade", "mildiou", "oidium", "pourriture", "rouille", "champignon",
    "ravageur", "ravageurs", "puceron", "pucerons", "mouche blanche", "acarien", "chenille",
    "taches", "fletri", "fletrit", "jaunit", "meurt", "tuta absoluta",
    "مرض", "امراض", "مريض", "مريضه", "عفن", "تعفن", "صدا", "فطر", "فطريات", "فيروس", "ذبول", "يذبل",
    "تذبل", "بقع", "افه", "افات", "آفات", "حشره", "حشرات", "من", "دوده", "ديدان", "تموت", "يموت",
    "نمل", "ذبابه بيضاء", "حفار",
]
# "من" is too short for substring matching: it is removed below.
DISEASE_TERMS = [t for t in DISEASE_TERMS if t != "من"]


# -------------------------------------------------------------------- messages

MESSAGES: Dict[str, Dict[str, str]] = {
    "refuse_dosage": {
        "en": ("I can't give pesticide doses, mixing ratios or spray schedules. The right amount depends on the "
               "product label, the crop, the pest and the law, and a wrong dose can harm you, your crop and "
               "consumers. Please check with an agricultural expert or your regional CRDA technician, and follow "
               "the label of the product. Your question has been sent to an expert."),
        "fr": ("Je ne peux pas donner de doses, de proportions de melange ni de calendrier de traitement pour les "
               "pesticides. La bonne quantite depend de l'etiquette du produit, de la culture, du ravageur et de "
               "la reglementation, et une mauvaise dose peut nuire a votre sante, a votre culture et aux "
               "consommateurs. Veuillez consulter un expert agricole ou un technicien du CRDA et suivre "
               "l'etiquette du produit. Votre question a ete transmise a un expert."),
        "ar": ("لا أستطيع إعطاء جرعات المبيدات أو نسب الخلط أو مواعيد الرش. الكمية الصحيحة تتبع بطاقة المنتج "
               "والمحصول والآفة والقانون، والجرعة الخاطئة قد تضرّك وتضرّ محصولك والمستهلكين. يرجى استشارة خبير "
               "زراعي أو فني المندوبية الجهوية للتنمية الفلاحية (CRDA) واتباع ما هو مكتوب على علبة المنتج. "
               "تم إرسال سؤالك إلى خبير."),
    },
    "refuse_emergency": {
        "en": ("This may be a poisoning emergency. Call SAMU on {num} or go to the nearest hospital now. Move the "
               "person or animal away from the product, do not induce vomiting unless a doctor tells you to, and "
               "bring the product label. I cannot give agricultural advice for this situation. An expert has "
               "also been notified."),
        "fr": ("Il peut s'agir d'une urgence d'intoxication. Appelez le SAMU au {num} ou allez a l'hopital le "
               "plus proche maintenant. Eloignez la personne ou l'animal du produit, ne provoquez pas de "
               "vomissement sauf avis d'un medecin, et apportez l'etiquette du produit. Je ne peux pas donner de "
               "conseil agricole dans cette situation. Un expert a aussi ete prevenu."),
        "ar": ("قد تكون هذه حالة تسمم طارئة. اتصل بالسامو على الرقم {num} أو توجّه إلى أقرب مستشفى الآن. أبعد "
               "الشخص أو الحيوان عن المنتج، ولا تحاول إجبار المصاب على التقيؤ إلا بتعليمات الطبيب، واحمل علبة "
               "المنتج معك. لا أستطيع تقديم نصيحة زراعية في هذه الحالة. تم إشعار خبير أيضاً."),
    },
    "expert_notice": {
        "en": "Check with an expert before acting on this. Your case has been sent to an agricultural expert.",
        "fr": "Consultez un expert avant d'agir. Votre cas a ete transmis a un expert agricole.",
        "ar": "استشر خبيراً زراعياً قبل التنفيذ. تم إرسال حالتك إلى خبير زراعي.",
    },
    "general_footer": {
        "en": "This is general guidance. Check with an expert for your specific field.",
        "fr": "Ceci est un conseil general. Consultez un expert pour votre parcelle.",
        "ar": "هذه نصيحة عامة. استشر خبيراً زراعياً بخصوص حقلك.",
    },
    "pesticide_topic": {
        "en": ("I don't recommend pesticide products or treatments. Identify the problem first and ask an "
               "agricultural expert or CRDA technician which product is allowed for your crop. Always follow "
               "the label and wear protective equipment."),
        "fr": ("Je ne recommande pas de produits ni de traitements phytosanitaires. Identifiez d'abord le "
               "probleme et demandez a un expert ou au CRDA quel produit est autorise pour votre culture. "
               "Suivez toujours l'etiquette et portez des protections."),
        "ar": ("لا أنصح بمنتجات أو علاجات المبيدات. حدّد المشكلة أولاً واسأل خبيراً زراعياً أو فني CRDA عن "
               "المنتج المسموح به لمحصولك. اتبع دائماً بطاقة المنتج وارتدِ معدات الحماية."),
    },
    "fertilizer_dosage": {
        "en": ("Exact fertilizer rates depend on a soil analysis, the crop stage and your yield target, so I "
               "can't give a specific amount."),
        "fr": ("Les doses d'engrais exactes dependent d'une analyse de sol, du stade de la culture et de "
               "l'objectif de rendement, donc je ne peux pas donner une quantite precise."),
        "ar": ("كميات السماد الدقيقة تعتمد على تحليل التربة ومرحلة المحصول والإنتاج المستهدف، لذلك لا أستطيع "
               "إعطاء كمية محددة."),
    },
    "disease": {
        "en": ("I can't diagnose a plant disease or pest from a text description. Please have it checked by an "
               "expert, ideally with a clear photo of the affected leaves."),
        "fr": ("Je ne peux pas diagnostiquer une maladie ou un ravageur a partir d'une description. Faites-le "
               "verifier par un expert, idealement avec une photo nette des feuilles touchees."),
        "ar": ("لا أستطيع تشخيص مرض أو آفة نباتية من وصف نصي. يرجى عرضها على خبير، ويفضل مع صورة واضحة للأوراق "
               "المصابة."),
    },
    "no_info": {
        "en": "I don't have enough reliable information to answer this question.",
        "fr": "Je n'ai pas assez d'informations fiables pour repondre a cette question.",
        "ar": "ليست لدي معلومات موثوقة كافية للإجابة عن هذا السؤال.",
    },
    "unclear": {
        "en": ("I didn't understand your question well enough to answer safely. Please say which crop and what "
               "problem you have. Check with an expert if it is urgent."),
        "fr": ("Je n'ai pas assez compris votre question pour repondre en securite. Precisez la culture et le "
               "probleme. Consultez un expert si c'est urgent."),
        "ar": ("لم أفهم سؤالك بما يكفي لأجيب بأمان. يرجى ذكر المحصول والمشكلة التي تواجهها. استشر خبيراً إذا "
               "كانت الحالة مستعجلة."),
    },
}


def message(key: str, lang: str) -> str:
    text = MESSAGES[key].get(lang) or MESSAGES[key]["en"]
    return text.format(num=EMERGENCY_NUMBER) if "{num}" in text else text


def expert_notice(lang: str) -> str:
    return message("expert_notice", lang)


def general_footer(lang: str) -> str:
    return message("general_footer", lang)


# ------------------------------------------------------------------- the rules

def evaluate_message(raw: str) -> Verdict:
    """Classify a farmer's message. Strongest category wins."""
    lang = detect_language(raw)
    text = normalize(raw)
    letters = re.findall(r"[a-z\u0600-\u06ff\u00e0-\u00ff]", text)

    if len(letters) < 4:
        return Verdict(Category.UNCLEAR, refuse=True, escalate=True, language=lang,
                       reply=message("unclear", lang))

    pesticide = _has(text, PESTICIDE_TERMS)

    if _has(text, POISONING_TERMS) and (pesticide or _has(text, POISON_CONTEXT_TERMS)):
        return Verdict(Category.EMERGENCY, refuse=True, escalate=True, language=lang,
                       reply=message("refuse_emergency", lang))

    if pesticide and _has(text, DOSAGE_TERMS):
        return Verdict(Category.PESTICIDE_DOSAGE, refuse=True, escalate=True, language=lang,
                       reply=message("refuse_dosage", lang))

    if pesticide:
        return Verdict(Category.PESTICIDE_TOPIC, refuse=True, escalate=True, language=lang,
                       reply=message("pesticide_topic", lang) + "\n\n" + expert_notice(lang))

    if _has(text, FERTILIZER_TERMS) and _has(text, DOSAGE_TERMS):
        return Verdict(Category.FERTILIZER_DOSAGE, refuse=True, escalate=True, language=lang,
                       reply=message("fertilizer_dosage", lang) + "\n\n" + expert_notice(lang))

    if _has(text, DISEASE_TERMS):
        return Verdict(Category.DISEASE, refuse=False, escalate=True, language=lang)

    return Verdict(Category.OK, refuse=False, escalate=False, language=lang)


def finalize_answer(answer: str, escalated: bool, lang: str) -> str:
    """Append the mandatory expert wording to an answer that is being returned."""
    return f"{answer}\n\n{expert_notice(lang) if escalated else general_footer(lang)}"
