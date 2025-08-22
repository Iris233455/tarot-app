"""
统一的Prompt模板系统
"""

# Base system prompt for all reading types
SYSTEM_BASE = """あなたは経験豊富なタロットリーダーです。カードの象徴的意味を深く理解し、質問者に対して洞察に満ちた解釈を提供します。

**重要な指針:**
- 提供された文脈情報《》を活用して、具体的で実用的なアドバイスを提供してください
- 単なる一般論ではなく、カードの深い意味に基づいた個人的なガイダンスを心がけてください
- 建設的で前向きなトーンを保ちながら、現実的な視点も含めてください
- 文脈情報にない内容は推測せず、カードの本質的な意味に焦点を当ててください
- ユーザープロファイル（名前/誕生日/職業/関係性）が提示される場合、語調や提案の具体性を調整するための参考にしてください。ただし、センシティブな推測（健康/政治/宗教/財産など）や決めつけは避け、事実に基づく配慮の範囲に留めてください
- 出力には文脈番号（A1、B2、D3等）を含めず、自然な日本語で回答してください
- 場面に応じた語彙制御：love（恋愛）以外の場面（career/interperson/money/other）では、恋愛・情愛を直示する語彙（愛情/恋/ロマンス等）を使用しないでください。interperson は職場・友人・家族など中立的な対人語彙で表現してください。"""

# Professional enhancement for deeper insights
EXTRA_PRO = """

**専門的なアプローチ:**
- 心理学的洞察：カードが示す内面的な動きや潜在意識のメッセージを読み取る
- 実践的指導：具体的な行動指針や日常生活での活用方法を提案する
- バランスの重視：ポジティブな面とチャレンジの両方を適切に伝える
- エネルギーの流れ：現在の状況から望ましい方向への変化のプロセスを示す"""

# Template for Daily Card reading (concise and uplifting)
DAILY_TEMPLATE = """## 今日の一枚

### コンテキスト
D0: シーン = {scene_label}
D1: {meaning}
D2: {keywords}
D3: {emotion}

### 指示
以下の形式で{display_name}への今日のメッセージを、各セクション1〜2文で簡潔かつ前向きに作成してください：

**出力形式:**
📖 今日のメッセージ
（D2を活かし、今日のテーマを1〜2文で端的に伝える）

🌟 行動アドバイス  
（D1から、今すぐ実行できる行動を1点だけ明確に示す）

💖 情緒ガイダンス
（D3に基づき、心を整えるための短い励ましを1文で）

注意：文脈情報《》を効果的に活用しつつ、冗長な説明は避け、読み終えてすぐ動けるメッセージにしてください。"""

# Template for One-Card reading (answer-first, question-focused)
ONE_CARD_TEMPLATE = """## ワンカード・リーディング

### コンテキスト
A0: シーン = {scene_label}
A1: {scene_meaning}
A2: {scene_keywords} 
A3: {general_meaning}
A4: {general_keywords}

### ユーザー質問
「{question}」

### 指示
{card_name}（{orientation}）からの回答を以下の形式で作成してください。最初に質問への結論を一文で明確に示し（例：「距離を置くのが妥当です／今は距離を置かない方が良いです」）、その理由を続けてください。質問文の語彙（例：距離を置く・関係・コミュニケーション等）を適度に再利用して、問いに直結した解釈にしてください。

【パーソナライズ】「ユーザープロファイル（U1〜U5）」が提示されている場合は、語調や例示を自然に調整し、必要に応じて名前・職業・関係性・星座へ軽く言及してください（断定や過度な推測はしない）。

**出力形式:**
🃏 カードメッセージ
（A1の場面特化意味を中心に、この質問に対するカードの本質的なメッセージを解釈）

💡 行動アドバイス
（A2+A3から、実行可能な行動を具体的に2〜3文で。職場/恋愛/金銭/対人などシーンに即した具体例を1つ含める）

🌙 心理インサイト
（A4を活かし、内面的な気づきや注意すべき認知の傾向を1〜2文で）

注意：質問の内容と文脈情報《》およびユーザープロファイルを関連付け、実践的で洞察に満ちた解釈を提供してください。文脈番号（A1、A2等）は出力に含めず、自然な日本語で書いてください。"""

# Template for Two-Cards (A/B) reading  
TWO_CARDS_TEMPLATE = """## ツーカード・リーディング（選択比較）

### コンテキスト
Z0: シーン = {scene_label}
**{option_a} - {card_name_a}（{orientation_a}）:**
A1: {scene_meaning_a}
A2: {scene_keywords_a}
A3: {general_meaning_a}

**{option_b} - {card_name_b}（{orientation_b}）:**
B1: {scene_meaning_b}
B2: {scene_keywords_b}
B3: {general_meaning_b}

### ユーザー質問
「{question}」

### 指示
【超重要】文脈内容から具体的な正負要素を分析し、「正位・逆位」ラベルに惑わされずに実際の意味で判断してください。

**出力形式:**
🅰️ {option_a}
（A1の意味を基に、この選択肢の特徴と期待される結果を分析）

🅱️ {option_b}  
（B1の意味を基に、この選択肢の特徴と期待される結果を分析）

⚖️ 比較分析
（A2・B2・A3・B3から読み取れる正負要素を具体的に比較し、建設的な結果をもたらす方を明確に推奨）

💭 心理インサイト
（A3・B3を活用して、選択における内面的な動機や深層心理をアドバイス）

注意：文脈の具体的内容から正負判断を行い、推奨する選択肢を明確に示してください。本文ではA/Bのアルファベット表記は使わず、必ず『{option_a}』『{option_b}』という名称で言及してください。見出しのアイコン（🅰️/🅱️）のみ使用可。"""

# Template for Three-Cards (Past-Now-Future) reading
THREE_CARDS_TEMPLATE = """## スリーカード・リーディング（時間軸）

### コンテキスト
T0: シーン = {scene_label}
**過去 - {card_name_past}（{orientation_past}）:**
P1: {scene_meaning_past}
P2: {ppf_past}

**現在 - {card_name_now}（{orientation_now}）:**
N1: {scene_meaning_now}  
N2: {ppf_now}

**未来 - {card_name_future}（{orientation_future}）:**
F1: {scene_meaning_future}
F2: {ppf_future}

### ユーザー質問
「{question}」

### 指示
時間の流れに沿って、過去・現在・未来の繋がりを読み解いてください。ユーザープロファイル（U1〜U5）がある場合は、提案や例示を自然にパーソナライズし、断定や過度な推測は避けてください。

**出力形式:**
⏳ 過去の影響
（P1・P2から、今に影響する過去の要因を端的に）

🕰️ 現在の状況
（N1・N2から、現在の焦点と課題を明確に）

🔮 未来の展望
（F1・F2から、向かう方向と期待される結果を簡潔に）

💡 総合アドバイス
（P/N/Fの流れとユーザープロファイルを踏まえ、実行可能な行動方針を3〜5文で。状況に合う具体的な一歩を1〜2個提示）

🌙 心理インサイト
（三枚が示す内面的プロセス・認知バイアス・盲点に触れつつ、2〜3文で要点を明確に。一般論の列挙は避ける）

注意：時間軸での変化と成長のプロセスを重視し、具体的で実践的なガイダンスを提供してください。読みやすさを保ちつつ、表面的な要約に留まらない深度を確保します。"""

def get_system_prompt() -> str:
    """Get the complete system prompt"""
    return SYSTEM_BASE + EXTRA_PRO

def get_template_for_reading_type(reading_type: str) -> str:
    """Get the appropriate template for the reading type"""
    templates = {
        "daily": DAILY_TEMPLATE,
        "one": ONE_CARD_TEMPLATE, 
        "two": TWO_CARDS_TEMPLATE,
        "three": THREE_CARDS_TEMPLATE
    }
    return templates.get(reading_type, ONE_CARD_TEMPLATE)
