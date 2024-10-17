
export default (req, res) => {
    console.debug('=====')
    res.status(200).json({ message: 'Hello World' });
};

function getRandomJapaneseCharacter() {
  const hiragana = "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん";
  const katakana = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン";
  const kanji = "一二三四五六七八九十日月火水木金土山川天空人";

  // 随机选择字符类型：平假名、片假名或汉字
  const types = [hiragana, katakana, kanji];
  const selectedType = types[Math.floor(Math.random() * types.length)];

  // 从所选类型中随机选择一个字符
  const randomChar = selectedType.charAt(Math.floor(Math.random() * selectedType.length));
  return randomChar;
}

function getRandomJapaneseString() {
  const length = Math.floor(Math.random() * 30) + 1;  // 随机生成1到30的长度
  let randomString = '';

  for (let i = 0; i < length; i++) {
    randomString += getRandomJapaneseCharacter();
  }

  return randomString;
}
