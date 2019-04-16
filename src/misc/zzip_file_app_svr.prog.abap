*&---------------------------------------------------------------------*
*& Report ZZIP_FILE_APP_SVR
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZZIP_FILE_APP_SVR.

DATA: lt_data TYPE TABLE OF x255.
DATA: ls_data LIKE LINE OF lt_data.

DATA: lv_zip_content TYPE xstring.
DATA: lv_dsn1(100) VALUE '/sap/NSP/sys/test.as'.
DATA: lv_dsn2(100) VALUE '/sap/NSP/sys/test2.mxml'.
DATA: lv_dsn3(100) VALUE '/sap/NSP/sys/testarchive.zip'.
DATA: lv_file_length    TYPE i.

DATA: lv_content TYPE xstring.
DATA: lo_zip TYPE REF TO cl_abap_zip.

CREATE OBJECT lo_zip.

* Read the data as a string
clear lv_content .
OPEN DATASET lv_dsn1 FOR INPUT IN BINARY MODE.
READ DATASET lv_dsn1 INTO lv_content .
CLOSE DATASET lv_dsn1.
lo_zip->add( name = 'test.as' content = lv_content ).

clear lv_content .
OPEN DATASET lv_dsn2 FOR INPUT IN BINARY MODE.
READ DATASET lv_dsn2 INTO lv_content .
CLOSE DATASET lv_dsn2.
lo_zip->add( name = 'test2.mxml' content = lv_content ).

lv_zip_content   = lo_zip->save( ).

* Conver the xstring content to binary
CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
  EXPORTING
    buffer        = lv_zip_content
  IMPORTING
    output_length = lv_file_length
  TABLES
    binary_tab    = lt_data.

OPEN DATASET lv_dsn3 FOR OUTPUT IN BINARY MODE.
LOOP AT lt_data INTO ls_data.
  TRANSFER ls_data TO lv_dsn3.
ENDLOOP.
