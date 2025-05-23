# 定数管理クラス
class Constants
  # ステータス
  HP_MIN = 0           # HP最小値
  ATTACK_VARIANCE = 3  # こうげき力のブレ幅

  # 行動選択
  ACTION_ATTACK = 1  # こうげき
  ACTION_ESCAPE = 2  # 逃げる

  # こうげきタイプ
  ATTACK_TYPE_NORMAL = 1  # 通常
  ATTACK_TYPE_MAGIC = 2   # 魔法こうげき
  
  # 書き出し間隔(秒)
  MESSAGE_DISPLAY_INTERVAL  = 1
end

# 各種表示メッセージを管理するクラス
class Message
  # 名前の入力をユーザーに求める
  def self.enter_name
    "↓勇者の名前を入力してください↓"
  end

  # ゲーム開始
  def self.game_start
    color("magenta", "\n◆◆◆ モンスターが現れた！ ◆◆◆")
  end

  # ラウンド数
  def self.round(round)
    color("cyan", "\n=== ラウンド #{round} ===")
  end

  # キャラクターのステータス
  def self.status(character)
    mark = character.is_alive ? "・" : color("red", "×")  # マーカー（生存:戦闘不能）
    name = character.name                                 # 名前
    hp = character.hp                                     # HP
    attack_damage = character.attack_damage               # こうげき力

    "#{mark}【#{name}】 HP：#{hp} こうげき力：#{attack_damage}"
  end

  # 操作
  def self.action_choice(hero)
    name = hero.name                    # 名前
    attack = Constants::ACTION_ATTACK   # こうげきの値
    escape = Constants::ACTION_ESCAPE   # 逃げるの値

    "\n#{name} のターンです。\n↓行動を選択してください↓\n" + color("yellow", "【#{attack}】こうげき\n【#{escape}】逃げる")
  end

  # 無効な選択肢が入力された
  def self.invalid_choice
    color("blue", "無効な選択肢です。再度選んでください。")
  end

  # こうげき
  def self.attack(attacker)
    name = attacker.name                            # 名前
    type = attacker.attack_type                     # タイプ
    normal_attack = Constants::ATTACK_TYPE_NORMAL   # 通常こうげきの値
    magic_attack = Constants::ATTACK_TYPE_MAGIC     # 魔法こうげきの値

    # こうげきタイプによってメッセージを変える
    case type
    when normal_attack
      # 通常こうげき
      return "#{name} のこうげき！"
    when magic_attack
      # 魔法こうげき
      return "#{name} は呪文をとなえた！"
    end
  end

  # ダメージ
  def self.damage(target, damage)
    name = target.name   # 名前

    "→#{name} に #{damage} のダメージ！"
  end

  # キャラクター戦闘不能
  def self.death(target)
    name = target.name   # 名前

    color("yellow", "→#{name} はたおれた！")
  end

  # 逃げる
  def self.escape(character)
    name = character.name  # 名前

    color("yellow", "#{name} は逃げ出した！\n")
  end

  # 勝敗
  def self.judge(hero_alive)
    hero_alive ? color("green", "◆◆◆ 勇者パーティの勝利！ ◆◆◆") : game_over()
  end

  # ゲームオーバー
  def self.game_over
    color("red", "◆◆◆ GAME OVER ◆◆◆")
  end

  # テキストに色付け
  def self.color(color, text)
    color_codes = {
      "red" => 31,
      "green" => 32,
      "yellow" => 33,
      "blue" => 34,
      "magenta" => 35,
      "cyan" => 36,
    }
  
    color_code = color_codes[color.downcase]
    color_code ? "\e[#{color_code}m#{text}\e[0m" : text
  end
end

# キャラクタークラス
class Character
  # アクセサ
  attr_accessor :name, :hp, :attack_damage, :attack_type ,:is_player, :is_alive

  # キャラクターの初期設定を行う
  def initialize(name, hp, attack_damage, attack_type, is_player = false)
    @name = name                    # キャラクター名
    @hp = hp                        # HP
    @attack_damage = attack_damage  # こうげき力
    @attack_type = attack_type      # こうげきタイプ
    @is_player = is_player          # プレイヤーフラグ
    @is_alive = true                # 生存フラグ
  end

  # ダメージ計算処理
  def calculate_damage
    variance = Constants::ATTACK_VARIANCE  # こうげき力のブレ幅

    # ダメージをランダムに決定(ステータスのこうげき力 ± ブレ幅)
    rand(@attack_damage - variance..@attack_damage + variance)
  end

  # ダメージ反映処理
  def receive_damage(damage)
    hp_min = Constants::HP_MIN # 0定義

    @hp -= damage  # ダメージ処理

    # 戦闘不能処理
    if @hp <= hp_min
      @hp = hp_min        # HPが0未満にならないよう調整
      @is_alive = false   # 生存フラグを下ろす
    end
  end
end

# ゲーム進行クラス
class Game
  # ゲームの初期設定を行う
  def initialize
    # 逃げるフラグを定義
    @escape_flg = false

    # プレイヤーに勇者の名前を入力させる
    display_message(Message.enter_name())  # メッセージ表示
    hero_name = gets.chomp              # 入力受付
    
    # キャラクターの作成
    @heroes = create_heroes(hero_name)  # 勇者パーティ
    @monsters = create_monsters()       # モンスターパーティ

    # 全パーティを格納
    @all_parties = [@heroes, @monsters]
  end

  # ゲーム開始処理
  def start
    round = 0    # ターン数

    # ゲーム開始メッセージ
    display_message(Message.game_start())

    # 戦闘ループ
    loop do
      # ゲームの戦況
      round += 1                            # ラウンド数カウント
      display_message(Message.round(round)) # ラウンド数表示
      display_status(@heroes)                  # ステータスの表示(勇者パーティ)
      display_status(@monsters)                # ステータスの表示(モンスターパーティ)

      # 勇者パーティのターン
      process_heroes_turn()
      break if @all_parties.any? { |party| party_destroyed?(party) } || @escape_flg  # 全滅チェックと逃げるフラグチェック

      # モンスターパーティのターン
      process_monsters_turn()
      break if @all_parties.any? { |party| party_destroyed?(party) } # 全滅チェック
    end

    # 勝敗表示
    unless @escape_flg
      # 通常の勝敗メッセージ
      display_message(Message.judge(party_destroyed?(@monsters)))
    else
      # 逃げ出した場合
      display_message(Message.game_over()) # ゲームオーバーの表示
    end
  end

  private

  #  勇者パーティの作成
  def create_heroes(hero_name)
    normal_attack = Constants::ATTACK_TYPE_NORMAL # 通常こうげきの値
    magic_attack = Constants::ATTACK_TYPE_MAGIC   # 魔法こうげきの値

    [
      Character.new(hero_name, 30, 6, normal_attack, true),  # プレイヤーが操作する勇者
      Character.new('魔法使い', 20, 8, magic_attack)          # 魔法使い(CPU)
    ]
  end

  # モンスターパーティの作成
  def create_monsters
    normal_attack = Constants::ATTACK_TYPE_NORMAL # 通常こうげきの値
    [
      Character.new('オーク', 30, 8, normal_attack),   # オーク(CPU)
      Character.new('ゴブリン', 25, 6, normal_attack)  # ゴブリン(CPU)
    ]
  end

  # メッセージ表示
  def display_message(message, wait = false)   # (文字列, 待機時間の有無)
    interval = Constants::MESSAGE_DISPLAY_INTERVAL  # 表示待機時間

    puts message            # 表示
    sleep interval if wait  # 指定がある場合は待つ
  end
  
  # パーティのステータスを表示する
  def display_status(party)
    party.each { |character| display_message(Message.status(character)) }
  end

  # 勇者パーティ側のターンを処理
  def process_heroes_turn
    attack_action = Constants::ACTION_ATTACK  # こうげき
    escape_action = Constants::ACTION_ESCAPE  # 逃げる

    @heroes.each do |character|
      next unless character.is_alive # 戦闘不能になったキャラクターは行動をスキップ
      loop do

        # 行動選択
        if character.is_player
          # プレイヤーの処理
          display_message(Message.action_choice(character))  # メッセージ
          choice = gets.to_i                                 # 選択を取得
        else
          # 味方の処理
          choice = attack_action  # こうげきを常時選択
        end

        # 行動
        case choice
        when attack_action
          # こうげき
          target_monster = @monsters.select(&:is_alive).sample          # 対象を絞る
          execute_attack(character, target_monster) if target_monster   # こうげき処理
          break
        when escape_action
          # 逃げる
          execute_escape(character)   # 逃げる処理
          return
        else
          # 無効な選択
          display_message(Message.invalid_choice())  # エラーメッセージ
        end
      end
    end
  end

  # モンスター側のターンを処理
  def process_monsters_turn
    @monsters.each do |monster|
      next unless monster.is_alive  # 戦闘不能になったキャラクターはスキップ

      # こうげき
      attack_target = @heroes.select(&:is_alive).sample         # 対象を絞る
      execute_attack(monster, attack_target) if attack_target   # こうげき処理
    end
  end

  # こうげき共通
  def execute_attack(attacker, target)
    # こうげきメッセージ
    display_message(Message.attack(attacker), true)

    # ダメージ処理
    damage = attacker.calculate_damage()                      # ダメージ計算
    target.receive_damage(damage)                           # ダメージ反映
    display_message(Message.damage(target, damage), true)   # メッセージ

    # 戦闘不能メッセージ
    display_message(Message.death(target), true) unless target.is_alive
  end

  # 逃げる処理
  def execute_escape(character)
    @escape_flg = true                                  # 逃げるフラグ
    display_message(Message.escape(character), true)    # 逃げる表示
  end

  # パーティの全滅チェック
  def party_destroyed?(party)
    party.none?(&:is_alive)  # 全滅ならtrue
  end
end

# ゲーム開始
game = Game.new
game.start