extends CharacterBody2D

@onready var sprite = $Sprite

# Характеристики персонажа
var speed = 200.0
var stamina = 100.0
var max_stamina = 100.0

# Внешность (для будущего спраита)
# Молодой парень: синяя рубашка, темные брюки, коричневые волосы
var appearance = {
    "hair_color": Color(0.4, 0.25, 0.1),  # Коричневые волосы
    "shirt_color": Color(0.2, 0.4, 0.7),  # Синяя рубашка
    "pants_color": Color(0.2, 0.2, 0.3),  # Темные брюки
    "skin_color": Color(1.0, 0.85, 0.7),  # Светлая кожа
    "age": "young_male"
}

func _ready():
    # Временная визуализация - рисуем персонажа программно
    draw_character()

func draw_character():
    # Создаем текстуру персонажа программно (молодой парень)
    var img = Image.create(32, 64, false, Image.FORMAT_RGBA8)
    
    # Цвета
    var hair = appearance["hair_color"]
    var shirt = appearance["shirt_color"]
    var pants = appearance["pants_color"]
    var skin = appearance["skin_color"]
    var shoes = Color(0.3, 0.15, 0.05)  # Коричневые ботинки
    
    # Рисуем тело (снизу вверх)
    for y in range(48, 64):  # Ноги/ботинки
        for x in range(8, 24):
            if y > 58:
                img.set_pixel(x, y, shoes)  # Ботинки
            else:
                img.set_pixel(x, y, pants)  # Брюки
    
    for y in range(28, 49):  # Туловище (рубашка)
        for x in range(6, 26):
            img.set_pixel(x, y, shirt)
    
    for y in range(10, 29):  # Голова и шея
        for x in range(8, 24):
            if y < 14 and (x < 10 or x > 22):  # Волосы по бокам
                img.set_pixel(x, y, hair)
            elif y >= 14 or (x >= 10 and x <= 22):
                img.set_pixel(x, y, skin)
    
    for y in range(4, 15):  # Волосы сверху
        for x in range(8, 24):
            if y < 12 and x >= 10 and x <= 22:
                img.set_pixel(x, y, hair)
    
    var texture = ImageTexture.create_from_image(img)
    sprite.texture = texture

func _physics_process(delta):
    var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    
    if input_direction:
        velocity = input_direction.normalized() * speed
    else:
        velocity = velocity.move_toward(Vector2.ZERO, speed * 0.2)
    
    move_and_slide()
    
    # Восстановление выносливости
    if stamina < max_stamina and not input_direction:
        stamina += delta * 10
