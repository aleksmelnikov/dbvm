[English](README.md) | [Russian](README.ru.md)

[English-orig](README-orig.en.md)

### DBVM

DBVM is an independent development based on a fork of the closed open-source project Altibase Community Edition, which existed from February 2018 to March 17, 2023. The DBVM project was founded in 2022.

Key features of DBVM (Altibase CE):
- supports both disk-based and in-memory data storage,
- architecturally, functionally and syntactically (commands) similar to the Oracle Database:
[Altibase/Oracle Comparison](https://docs.altibase.com/pages/viewpage.action?pageId=16875638),
[ORACLE to ALTIBASE Conversion Guide](https://docs.altibase.com/display/arch/ORACLE+to+ALTIBASE+Conversion+Guide).

### Licensing

The DBVM project fully complies with the licenses of the original project:

|Component                             | Altibase CE License  | DBVM License   |
|--------------------------------------|----------------------|----------------|
|DBMS Server                           | GNU AGPLv3           | GNU AGPLv3     |
|General Polygon Clipper Library<br>Altibase Polygon Clipper Library<br> - interchangeable polygon libraries;<br>(can be selected in the DB config file)|GPC license (1)<br>GNU AGPLv3|GPC license (1)<br>GNU AGPLv3|
|DBMS Client                           | GNU LGPLv3           | GNU LGPLv3     |

(1) - Since 2020, the license requirements are no longer active:
[https://en.wikipedia.org/wiki/General_Polygon_Clipper](https://en.wikipedia.org/wiki/General_Polygon_Clipper),
[https://github.com/rickbrew/GeneralPolygonClipper](https://github.com/rickbrew/GeneralPolygonClipper).

