class MoodAyah {
  final String arabic;
  final String english;
  final String urdu;
  final String reference;

  MoodAyah({required this.arabic, required this.english, required this.urdu, required this.reference});
}

class MoodCategory {
  final String name;
  final String icon;
  final List<MoodAyah> ayahs;

  MoodCategory({required this.name, required this.icon, required this.ayahs});
}

final List<MoodCategory> moodDataset = [
  MoodCategory(
    name: "Sad",
    icon: "😔",
    ayahs: [
      MoodAyah(arabic: "إِنَّ مَعَ الْعُسْرِ يُسْرًا ۞ إِنَّ مَعَ الْعُسْرِ يُسْرًا", english: "For indeed, with hardship will be ease. Indeed, with hardship will be ease.", urdu: "پس بے شک مشکل کے ساتھ آسانی ہے۔ بے شک مشکل کے ساتھ آسانی ہے۔", reference: "Surah Ash-Sharh (94:5-6)"),
      MoodAyah(arabic: "مَا وَدَّعَكَ رَبُّكَ وَمَا قَلَىٰ", english: "Your Lord has not taken leave of you, [O Muhammad], nor has He detested you.", urdu: "آپ کے رب نے نہ تو آپ کو چھوڑا ہے اور نہ ہی وہ آپ سے ناراض ہوا ہے۔", reference: "Surah Ad-Duha (93:3)"),
      MoodAyah(arabic: "قَالَ إِنَّمَا أَشْكُو بَثِّي وَحُزْنِي إِلَى اللَّهِ", english: "He said, 'I only complain of my suffering and my grief to Allah.'", urdu: "انہوں نے کہا، 'میں تو اپنی پریشانی اور دکھ کا اظہار صرف اللہ سے کرتا ہوں۔'", reference: "Surah Yusuf (12:86)"),
    ],
  ),
  MoodCategory(
    name: "Anxious",
    icon: "😰",
    ayahs: [
      MoodAyah(arabic: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ", english: "Unquestionably, by the remembrance of Allah hearts find rest.", urdu: "آگاہ ہو جاؤ! اللہ کے ذکر سے ہی دلوں کو سکون ملتا ہے۔", reference: "Surah Ar-Ra'd (13:28)"),
      MoodAyah(arabic: "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا", english: "Allah does not burden a soul beyond that it can bear.", urdu: "اللہ کسی جان پر اس کی طاقت سے زیادہ بوجھ نہیں ڈالتا۔", reference: "Surah Al-Baqarah (2:286)"),
      MoodAyah(arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ", english: "Sufficient for us is Allah, and [He is] the best Disposer of affairs.", urdu: "ہمارے لیے اللہ ہی کافی ہے اور وہ بہترین کارساز ہے۔", reference: "Surah Al-Imran (3:173)"),
    ],
  ),
  MoodCategory(
    name: "Angry",
    icon: "😠",
    ayahs: [
      MoodAyah(arabic: "وَالْكَاظِمِينَ الْغَيْظَ وَالْعَافِينَ عَنِ النَّاسِ ۗ وَاللَّهُ يُحِبُّ الْمُحْسِنِينَ", english: "And who restrain anger and who pardon the people - and Allah loves the doers of good.", urdu: "اور غصے ko پینے والے اور لوگوں کو معاف کرنے والے؛ اور اللہ احسان کرنے والوں سے محبت کرتا ہے۔", reference: "Surah Al-Imran (3:134)"),
      MoodAyah(arabic: "ادْفَعْ بِالَّتِي هِيَ أَحْسَنُ", english: "Repel [evil] by that which is better.", urdu: "برائی کو بہترین طریقے سے دور کرو۔", reference: "Surah Fussilat (41:34)"),
    ],
  ),
  MoodCategory(
    name: "Lonely",
    icon: "👤",
    ayahs: [
      MoodAyah(arabic: "وَنَحْنُ أَقْرَبُ إِلَيْهِ مِنْ حَبْلِ الْوَرِيدِ", english: "And We are closer to him than his jugular vein.", urdu: "اور ہم اس کی شہ رگ سے بھی زیادہ قریب ہیں۔", reference: "Surah Qaf (50:16)"),
      MoodAyah(arabic: "فَاذْكُرُونِي أَذْكُرْكُمْ", english: "So remember Me; I will remember you.", urdu: "تم مجھے یاد کرو، میں تمہیں یاد کروں گا۔", reference: "Surah Al-Baqarah (2:152)"),
      MoodAyah(arabic: "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ", english: "And He is with you wherever you are.", urdu: "اور وہ تمہارے ساتھ ہے جہاں کہیں بھی تم ہو۔", reference: "Surah Al-Hadid (57:4)"),
    ],
  ),
  MoodCategory(
    name: "Grateful",
    icon: "😇",
    ayahs: [
      MoodAyah(arabic: "لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ", english: "If you are grateful, I will surely increase you [in favor].", urdu: "اگر تم شکر ادا کرو گے تو میں تمہیں اور زیادہ دوں گا۔", reference: "Surah Ibrahim (14:7)"),
      MoodAyah(arabic: "فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ", english: "So which of the favors of your Lord would you deny?", urdu: "پس تم دونوں اپنے رب کی کس کس نعمت کو جھٹالؤ گے؟", reference: "Surah Ar-Rahman (55:13)"),
    ],
  ),
  MoodCategory(
    name: "Fearful",
    icon: "😨",
    ayahs: [
      MoodAyah(arabic: "وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ", english: "And whoever relies upon Allah - then He is sufficient for him.", urdu: "اور جو اللہ پر بھروسہ کرے گا تو وہ اس کے لیے کافی ہے۔", reference: "Surah At-Talaq (65:3)"),
      MoodAyah(arabic: "لَا تَخَافَا ۖ إِنَّنِي مَعَكُمَا أَسْمَعُ وَأَرَىٰ", english: "Fear not. Indeed, I am with you both; I hear and I see.", urdu: "ڈرو مت، میں تم دونوں کے ساتھ ہوں، سنتا ہوں اور دیکھتا ہوں۔", reference: "Surah Taha (20:46)"),
    ],
  ),
];
