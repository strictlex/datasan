# Добавление нового метода маскирования в регрессионные тесты

Чтобы новый метод `PFLB_ENCODE_HASH_XXX` автоматически проверялся на 100k строках, выполните **один шаг**:

1. Откройте `config/methods_scale.yaml`.
2. Добавьте в список `methods` следующую запись:

```yaml
  - function: PFLB_ENCODE_HASH_XXX
    data_type: VARCHAR2      # или NUMBER, DATE
    generator: <один из ключей ниже>
    validator: <один из ключей ниже>
    description: Краткое описание


Доступные ключи для generator и validator:

Ключ	        Тип данных	Описание
inn_12	        VARCHAR2	ИНН физического лица (12 цифр)
snils	        VARCHAR2	СНИЛС (11 цифр)
phone	        VARCHAR2	Телефон +7XXXXXXXXXX
passport	    VARCHAR2	Паспорт "1234 567890"
ip	            VARCHAR2	IP-адрес
ogrn	        VARCHAR2	ОГРН (13 цифр)
cardnumber	    VARCHAR2	Номер карты (16 цифр)
date	        DATE	    Дата YYYY-MM-DD
text_cyrillic	VARCHAR2	Произвольный кириллический текст
full_name	    VARCHAR2	ФИО "Иванов Иван"

Если ваш метод работает с одним из этих типов данных – просто выберите соответствующий ключ и для generator, и для validator.
Если метод не подходит ни под один существующий тип – обратитесь к разработчику тестов для добавления нового генератора и валидатора.

После добавления строки в YAML запустите smoke-тесты: 
pytest -m smoke -k scale. Новый метод будет проверен автоматически.