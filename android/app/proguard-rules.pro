# Google ML Kit Text Recognition - modules linguistiques non utilisés.
# Le plugin google_mlkit_text_recognition référence en interne des classes
# pour le chinois, le japonais, le coréen et le devanagari (hindi), même si
# seul le module latin est réellement inclus comme dépendance. Sans ces
# règles, R8 échoue en mode release car il ne trouve pas ces classes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**