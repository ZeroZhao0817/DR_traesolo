/// 名言数据
/// 包含毛泽东选集、名人名言、哲学格言等
class QuoteData {
  QuoteData._();

  /// 工作阶段名言（鼓励工作）
  static const List<Map<String, String>> workQuotes = [
    {'text': '一切反动派都是纸老虎。', 'author': '毛泽东'},
    {'text': '没有调查就没有发言权。', 'author': '毛泽东'},
    {'text': '星星之火，可以燎原。', 'author': '毛泽东'},
    {'text': '为有牺牲多壮志，敢教日月换新天。', 'author': '毛泽东'},
    {'text': '下定决心，不怕牺牲，排除万难，去争取胜利。', 'author': '毛泽东'},
    {'text': '世上无难事，只要肯登攀。', 'author': '毛泽东'},
    {'text': '一万年太久，只争朝夕。', 'author': '毛泽东'},
    {'text': '自力更生，艰苦奋斗。', 'author': '毛泽东'},
    {'text': '在战略上要藐视敌人，在战术上要重视敌人。', 'author': '毛泽东'},
    {'text': '知识就是力量。', 'author': '培根'},
    {'text': '天行健，君子以自强不息。', 'author': '《周易》'},
    {'text': '业精于勤，荒于嬉；行成于思，毁于随。', 'author': '韩愈'},
    {'text': '不积跬步，无以至千里；不积小流，无以成江海。', 'author': '荀子'},
    {'text': '路漫漫其修远兮，吾将上下而求索。', 'author': '屈原'},
    {'text': '宝剑锋从磨砺出，梅花香自苦寒来。', 'author': '古诗'},
    {'text': '千里之行，始于足下。', 'author': '老子'},
    {'text': '业精于勤，荒于嬉。', 'author': '韩愈'},
    {'text': '志不强者智不达。', 'author': '墨子'},
    {'text': '穷且益坚，不坠青云之志。', 'author': '王勃'},
    {'text': '博观而约取，厚积而薄发。', 'author': '苏轼'},
    {'text': '纸上得来终觉浅，绝知此事要躬行。', 'author': '陆游'},
    {'text': '锲而舍之，朽木不折；锲而不舍，金石可镂。', 'author': '荀子'},
    {'text': '少年易老学难成，一寸光阴不可轻。', 'author': '朱熹'},
    {'text': '明日复明日，明日何其多。', 'author': '钱福'},
    {'text': '盛年不重来，一日难再晨。', 'author': '陶渊明'},
  ];

  /// 休息阶段名言（提醒休息）
  static const List<Map<String, String>> breakQuotes = [
    {'text': '身体是革命的本钱。', 'author': '毛泽东'},
    {'text': '劳逸结合，才能走得更远。', 'author': '谚语'},
    {'text': '休息是为了更好地工作。', 'author': '列宁'},
    {'text': '适当放松，提高效率。', 'author': '谚语'},
    {'text': '站起来活动一下，眼睛也需要休息。', 'author': '健康提示'},
    {'text': '一张一弛，文武之道也。', 'author': '《礼记》'},
    {'text': '不会休息的人，就不会工作。', 'author': '列宁'},
    {'text': '磨刀不误砍柴工。', 'author': '谚语'},
    {'text': '静以修身，俭以养德。', 'author': '诸葛亮'},
    {'text': '采菊东篱下，悠然见南山。', 'author': '陶渊明'},
    {'text': '行到水穷处，坐看云起时。', 'author': '王维'},
    {'text': '宠辱不惊，看庭前花开花落。', 'author': '《菜根谭》'},
    {'text': '非淡泊无以明志，非宁静无以致远。', 'author': '诸葛亮'},
    {'text': '心若冰清，天塌不惊。', 'author': '《冰心诀》'},
    {'text': '凡事预则立，不预则废。', 'author': '《礼记》'},
    {'text': '欲速则不达，见小利则大事不成。', 'author': '孔子'},
    {'text': '小不忍则乱大谋。', 'author': '孔子'},
    {'text': '己所不欲，勿施于人。', 'author': '孔子'},
    {'text': '学而不思则罔，思而不学则殆。', 'author': '孔子'},
    {'text': '三人行，必有我师焉。', 'author': '孔子'},
    {'text': '温故而知新，可以为师矣。', 'author': '孔子'},
    {'text': '知之者不如好之者，好之者不如乐之者。', 'author': '孔子'},
    {'text': '工欲善其事，必先利其器。', 'author': '孔子'},
    {'text': '千里之堤，溃于蚁穴。', 'author': '韩非子'},
    {'text': '满招损，谦受益。', 'author': '《尚书》'},
  ];

  /// 获取随机名言
  static Map<String, String> getRandomQuote(bool isWorkPhase, int seed) {
    final quotes = isWorkPhase ? workQuotes : breakQuotes;
    final index = seed % quotes.length;
    return quotes[index];
  }
}

/// 颈椎放松动作数据
class NeckExerciseData {
  NeckExerciseData._();

  static const List<Map<String, dynamic>> exercises = [
    {
      'name': '米字型运动',
      'description': '头部依次向前、后、左、右、左前、左后、右前、右后缓慢转动',
      'duration': '每个方向 5 秒',
      'icon': '↔️',
    },
    {
      'name': '颈部侧屈',
      'description': '头部向左侧倾斜，右肩保持不动，感受右侧颈部拉伸',
      'duration': '左右各 10 秒',
      'icon': '↕️',
    },
    {
      'name': '颈部旋转',
      'description': '头部缓慢向左旋转至极限，再向右旋转至极限',
      'duration': '左右各 5 秒',
      'icon': '🔄',
    },
    {
      'name': '耸肩放松',
      'description': '双肩向上耸起，保持 3 秒，然后放松下沉',
      'duration': '重复 5 次',
      'icon': '📈',
    },
    {
      'name': '下巴收缩',
      'description': '下巴向内收，保持颈部伸直，感受颈部后侧拉伸',
      'duration': '保持 10 秒',
      'icon': '👤',
    },
    {
      'name': '眼部放松',
      'description': '闭眼，眼球顺时针、逆时针各转动 5 圈',
      'duration': '约 30 秒',
      'icon': '👁️',
    },
    {
      'name': '肩部环绕',
      'description': '双肩向后做环绕运动，放松肩颈肌肉',
      'duration': '前后各 5 圈',
      'icon': '⭕',
    },
    {
      'name': '深呼吸',
      'description': '缓慢吸气 4 秒，屏息 4 秒，呼气 6 秒',
      'duration': '重复 3 次',
      'icon': '🫁',
    },
  ];

  /// 获取随机动作
  static Map<String, dynamic> getRandomExercise(int seed) {
    final index = seed % exercises.length;
    return exercises[index];
  }
}
