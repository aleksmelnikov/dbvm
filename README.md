### DBVM

СУБД DBVM - это собственная разработка на основе форка закрытого opensource проекта Altibase Community Edition, который существовал с февраля 2018 по 17 марта 2023. Проект DBVM основан в 2022 году.

Исключительные особенности СУБД DBVM (Altibase CE):
- позволяет размещать данные на диске и в памяти (in-memory),
- архитектурно, функционально и синтаксически (команды) схожа с базой данных Oracle:
[Altibase/Oracle Comparison](https://docs.altibase.com/pages/viewpage.action?pageId=16875638),
[ORACLE to ALTIBASE Conversion Guide](https://docs.altibase.com/display/arch/ORACLE+to+ALTIBASE+Conversion+Guide).

### Лицензия
- Проект DBVM полностью соблюдает лицензии исходного проекта:

|Компонента                            | Лицензия Altibase CE | Лицензия DBVM  |
|--------------------------------------|----------------------|----------------|
|Сервер СУБД                           | GNU AGPLv3           | GNU AGPLv3     |
|General Polygon Clipper Library<br>Altibase Polygon Clipper Library<br> - взаимозаменяемые библиотеки полигонов<br>(можно переключить в конф. файле базы)|GPC license (1)<br>GNU AGPLv3|GPC license (1)<br>GNU AGPLv3|
|Клиент СУБД                           | GNU LGPLv3           | GNU LGPLv3     |

(1) - с 2020г. требования лицензии не действуют:
[https://en.wikipedia.org/wiki/General_Polygon_Clipper](https://en.wikipedia.org/wiki/General_Polygon_Clipper),
[https://github.com/rickbrew/GeneralPolygonClipper](https://github.com/rickbrew/GeneralPolygonClipper).

