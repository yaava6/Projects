import pandas as pd
import sqlite3
import urllib.request
import os

## Установите пакет " openpyxl "

'''
 Данные с 2 недели 4 курса Курсера
 
'''
dbname = "tickets.sqlite"  ## Название базы данных
conn = sqlite3.connect(dbname)  ## Создаем объект для подключения к базе данных
cur = conn.cursor()  ## Создаем объект курсора для манипуляции с запросами

## Путь для сохранение отчетов. Удалем последние 8 элементов строки (/main.py)
file_path = os.path.realpath(__file__)[:-8]


def import_data():
    """
     Присваиваем к значеию url ccылку на сайт c данными,
     затем сохраняем .csv файл в папке проекта.
     Код был использован с помощью данных  3 курса 4 недели

     С помощью библиотеки pandas для обработки и анализа данных, мы читаем сохраненный файл.

     :returns
      pandas.DataFrame

     """
    url = "https://query.data.world/s/t6vxpujbouhsxextul4fagq4qeycwq"
    urllib.request.urlretrieve(url, 'tickets_mos.csv')
    return pd.read_csv('tickets_mos.csv')


def insert_data(data):
    """

      Удалили не актульные данные, эти параметры содержали одинкаовые данные для каждого стольбца

      Запускаем sqlite3 запрос. Удаляем таблицу Tickets, если такой существует
     (при каждом запуске программы, создается новая таблица)
     id: первичный ключ, AUTOINCREMENT  значит что при каждом добавлении даных,
      id увеличивется на 1.

     :parameter:
         data: pandas.Dataframe

         """
    data.drop(columns=['trip_class', 'distance', 'actual'], axis=1, inplace=True)
    print("Hey")

    cur.executescript('''
    	DROP TABLE IF EXISTS Tickets;
    	CREATE TABLE Tickets (
    		id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,
    		VALUE REAL NOT NULL,
    		ORIGIN TEXT NOT NULL,
    		NUMBER_OF_CHANGES INTEGER NOT NULL,
    		WEB_SOURCE TEXT NOT NULL,
    		FOUND_AT TEXT NOT NULL,
    		DESTINATION TEXT NOT NULL,
    		DEPART_DATE TEXT NOT NULL,
    		AIRLINE TEXT NOT NULL
    	);
    ''')

    '''
        С помощью цикла, пробегаемся по DataFrame c помощью функции intertuples.
        row: Каждый row, представлен ввиде tuple
        Pandas(_0=0, value=10570.0, origin='MOW'...)
        Мы не отправляем данные от row[0]. так как хотим показать работу AUTOINCREMENT.
        
        В коде использованны исходные коды от 4 курса, 4 недели
     '''

    for row in data.itertuples(index=False):
        insert_sql = f"INSERT INTO Tickets " \
                     f"(VALUE, ORIGIN, NUMBER_OF_CHANGES,WEB_SOURCE,FOUND_AT, " \
                     f"DESTINATION,DEPART_DATE, AIRLINE) " \
                     f"values ({row[1]},'{row[2]}',{row[3]},'{row[4]}'," \
                     f"'{row[5]}','{row[6]}','{row[7]}','{row[8]}')"
        conn.execute(insert_sql)
    conn.commit()


def setFrameOptions():
    """
      Для полного ввида dataFrame в консоле, были введены опции pandas.
      11 столбоц( все существущее столбцы, без опции программа выводит 5 колон)
      ширина 400, выбранный удобный вид ширины
    """
    pd.set_option('display.max_columns', 11)
    pd.set_option('display.width', 400)


# show all data
def show_all():
    """
       Создаем запрос для вывода всех данных.
       С помощью функции .fetchall() получаем результаты запроса и конвертируем данные в DataFrame.
        Выводим эти данные пользователю и сохранем файл в указанным месте.
     """
    query = f"SELECT * FROM Tickets"
    cur.execute(query)
    df = pd.DataFrame(cur.fetchall(),
                      columns=['id', 'VALUE',
                               'ORIGIN', 'NUMBER_OF_CHANGES',
                               'WEB_SOURCE', 'FOUND_AT',
                               'DESTINATION', 'DEPART_DATE',
                               'AIRLINE'])
    df.to_excel(file_path + r'\all_data.xlsx', index=False, header=True)
    print(df)
    print("Данные сохранены в Excel файле")


# show ordered data by value
def sort_by_value(order):
    """
           Создаем запрос для вывода сортированных данных по ценам.
           В зависимости от полученного str(order) выполняется запрос query.
           С помощью функции .fetchall() получаем результаты запроса и конвертируем данные в DataFrame.
            Выводим эти данные пользователю и сохранем файл в указанным месте.

            :argument:
              order: str(asc or desc)
         """
    if order == 'asc':
        query = f"SELECT * FROM Tickets ORDER BY value ASC"
    else:
        query = f"SELECT * FROM Tickets ORDER BY value DESC "
    cur.execute(query)

    df = pd.DataFrame(cur.fetchall(),
                      columns=['id', 'VALUE',
                               'ORIGIN', 'NUMBER_OF_CHANGES',
                               'WEB_SOURCE', 'FOUND_AT',
                               'DESTINATION', 'DEPART_DATE',
                               'AIRLINE'])
    print(df)
    print("Данные сохранены в Excel файле")
    df.to_excel(file_path + r'\sorted_by_value.xlsx', index=False, header=True)


def show_order():
    """
     Мы предостоваляем пользователю выбор. Вывести данные  по возрастанию, либо по убыванию.
     Пользователь должен ввести 1 и 2. Программа проверяет с помощью try/catch
     введеный символ int или нет.
     Если да, то условная оператор проверяет введеное число на 1 или 2.
     Если нет, то попросит ввести число.

    """
    print("1. По убыванию \n"
          "2. По возрастанию")
    inp = input("Выберите тип сортировки: ")
    try:
        choice = int(inp)
        if choice == 1:
            sort_by_value('desc')
        elif choice == 2:
            sort_by_value('asc')
        else:
            print("\n Выберите правильное число!\n")
            show_order()
    except ValueError:
        print("\nВведите число!\n")
        show_order()


def show_no_changes():
    """
    Выводит данные в которых number_of_changes = 0. Это значит количество изменение в рейсе.
    """
    query = f"SELECT number_of_changes," \
            f" origin, destination, " \
            f"airline FROM Tickets WHERE number_of_changes = 0"
    cur.execute(query)

    df = pd.DataFrame(cur.fetchall(),
                      columns=['NUMBER_OF_CHANGES', 'ORIGIN',
                               'DESTINATION', 'AIRLINE'])
    df.to_excel(file_path + r'\no_changes.xlsx', index=False, header=True)
    print(df)
    print("Данные сохранены в Excel файле")


def show_web_sources():
    """
     С базы данных достаем список веб-источников.
     Чтобы дать пользователю выбрать источник который, он хотел бы посмотреть.
      .unique() с этой функциией создаем из уникальных данных по данным WEB_SOURCE и выводми для пользовтеля.
      Берем данные index - 1, потому что нумерации идут от 0.

    """
    query1 = f"SELECT web_source FROM Tickets"
    cur.execute(query1)
    data = pd.DataFrame(cur.fetchall(),
                        columns=['WEB_SOURCE'])

    web_list = data['WEB_SOURCE'].unique()
    pos = 1
    for source in web_list:
        print(str(pos) + ". " + source)
        pos += 1

    index = int(input("Выберите источник: "))
    choice = web_list[index - 1]
    query = f"SELECT web_source, origin," \
            f"destination, airline FROM Tickets WHERE web_source=?"
    cur.execute(query, (choice,))
    df = pd.DataFrame(cur.fetchall(),
                      columns=['WEB_SOURCE', 'ORIGIN',
                               'DESTINATION', 'AIRLINE'])
    ## Надо изменить путь для проверки
    df.to_excel(file_path + r'\web_sources.xlsx', index=False, header=True)
    print(df)
    print("Данные сохранены в Excel файле")


def show_options():
    """
    Выводим опции который пользовтель может выбрать.
    При возвращении функции false, show_options заканичается цикл.
    При True, цикл продолжает работать и показывает функцию show_options после каждого запроса.
    :return:
    """
    print(
        "1. Вывести все данные",
        "2. Вывести данные сортированные по ценам",
        "3. Вывести данные по интернет источникам",
        "4. Вывести данные без измененных рейсов",
        "5. Выйти из программы",
        sep='\n')
    inp = input("Выберите: ")
    try:
        choice = int(inp)
        if choice == 1:
            show_all()
        elif choice == 2:
            show_order()
        elif choice == 3:
            show_web_sources()
        elif choice == 4:
            show_no_changes()
        elif choice == 5:
            return False
        else:
            print("\n Выберите правильное число!\n")
    except ValueError:
        print("\nВведите число!\n")
    return True


def main():
    """
    С этой функции начинает работать программа.
    Вызваем функцию для получения данных.
    Вызываем функции для заполнения полученных данных в базу данных.
    Вызываем функии для обозначения опции pandas.

    Используем  while, чтобы функция show_options() в main()
    не преращало работу, пока не был выбран выход из программы
    :return:
    """

    data = import_data()
    insert_data(data)
    setFrameOptions()
    if __name__ != "__main__":
        return
    # show main menu until exit is choosen
    while show_options():
        pass


main()

conn.close()
