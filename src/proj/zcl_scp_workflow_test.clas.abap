class zcl_scp_workflow_test definition
  public
  final
  create public .

  public section.

    interfaces if_oo_adt_classrun.

  protected section.
  private section.

    types: begin of ts_attr_value,
             objkey type string,  "WF Definition or WF instance
             id     type string,
             value  type string,
           end of ts_attr_value.

    types: tt_attr_value type standard table of ts_attr_value with key id.

    methods: parse_json importing iv_objkey            type string default ''
                                  iv_json              type string
                        returning value(rt_attr_value) type tt_attr_value.

endclass.

class zcl_scp_workflow_test implementation.

  method if_oo_adt_classrun~main.

    data: lv_json type string.
    data: lt_attr_value type tt_attr_value.
    data: ls_attr_value like line of lt_attr_value.

******
* Create instance of the Workflow API class, passing scp workflow runtime url, user and password
******
    data(lo_scp_worflow_api) = new zcl_scp_workflow_api(
                                      iv_url = '<valid_workflow_runtime_url>'
                                      iv_user = '<valid_user>'
                                      iv_password = '<valid_password>' ).

******
* Get the workflow definition
******
    lv_json = lo_scp_worflow_api->get_wf_definition( iv_definition_id = 'approveproduct' ).
    lt_attr_value = me->parse_json( iv_objkey = 'approveproduct' iv_json = lv_json ).
    out->write( lt_attr_value ).

******
* Get workflow definition model
******
    lv_json = lo_scp_worflow_api->get_wf_definition_model( iv_definition_id = 'approveproduct' ) .
    lt_attr_value = me->parse_json( iv_objkey = 'approveproduct' iv_json = lv_json ).
    out->write( lt_attr_value ).

******
* Get workflow instances that are running
******
    lv_json =  lo_scp_worflow_api->get_wf_instances_by_status(
                                          iv_definition_id = 'approveproduct'
                                          iv_status = 'RUNNING' ).
    lt_attr_value = me->parse_json( iv_json = lv_json ).
    out->write( lt_attr_value ).

******
*  This section shows how to delete all instance of a workflow definition by their status.
******
* Get all RUNNING instances and delete
    lv_json =  lo_scp_worflow_api->get_wf_instances_by_status(
                                          iv_definition_id = 'approveproduct'
                                          iv_status = 'RUNNING' ).
    loop at lt_attr_value into ls_attr_value where id = 'id'.
      out->write( 'Deleting instance.....' && ls_attr_value-value ).
      out->write( lo_scp_worflow_api->delete_wf_instances( ls_attr_value-value ) ).
    endloop.
* Get all COMPLETED instances and delete
    lv_json =  lo_scp_worflow_api->get_wf_instances_by_status(
                                          iv_definition_id = 'approveproduct'
                                          iv_status = 'COMPLETED' ).
    lt_attr_value = me->parse_json( iv_json = lv_json ).
    loop at lt_attr_value into ls_attr_value where id = 'id'.
      out->write( 'Deleting instance.....' && ls_attr_value-value ).
      out->write( lo_scp_worflow_api->delete_wf_instances( ls_attr_value-value ) ).
    endloop.
* Get all ERRONEOUS instances and delete
    lv_json =  lo_scp_worflow_api->get_wf_instances_by_status(
                                          iv_definition_id = 'approveproduct'
                                          iv_status = 'ERRONEOUS' ).
    lt_attr_value = me->parse_json( iv_json = lv_json ).
    loop at lt_attr_value into ls_attr_value where id = 'id'.
      out->write( 'Deleting instance.....' && ls_attr_value-value ).
      out->write( lo_scp_worflow_api->delete_wf_instances( ls_attr_value-value ) ).
    endloop.

******
*   This section shows how to use the WF API to create instances of a workflow.
******

* Set up some data
    types: begin of ts_products,
             productid   type string,
             productdesc type string,
           end of ts_products.
    types: tt_products type standard table of ts_products with empty key.
    data(lt_products) = value tt_products( ( productid =  `1000050001` productdesc = 'Widget A')
                                           ( productid =  `1000050002` productdesc = 'Widget B')
                                           ( productid =  `1000050003` productdesc = 'Widget C')   ).
    data: ls_products type ts_products.

* Create a new workflow instance, setting context.  Parse json response and write out to console
    loop at lt_products into ls_products.

      lv_json =  lo_scp_worflow_api->create_wf_instance(
                                        iv_definition_id = 'approveproduct'
                                        iv_context = '{ "productDesc": "' && ls_products-productdesc && '", ' &&
                                                     '"productId": "' && ls_products-productid  && '", ' &&
                                                     '"approverUserId": "I816013", ' &&
                                                     '"approvalStatus": "", ' &&
                                                     '"approvalStatusUpdatedBy": "", ' &&
                                                     '"approvalStatusUpdatedAt": "", ' &&
                                                     '"recipientEmail": "<valid_email_address>"} ') .
      lt_attr_value = me->parse_json( iv_objkey = ls_products-productid iv_json = lv_json ).
      out->write( lt_attr_value ).

    endloop.

******
*   This section shows how to use the WF API to get the instance details by business key,
*   get the current context of the workflow instance,  update a context value,
*   and set a user task instance status.
******

    loop at lt_products into ls_products.

* Use API to get the newly created workflow instance by the business key.
      lv_json =  lo_scp_worflow_api->get_wf_instance_by_businesskey(
                                            iv_businesskey = ls_products-productid ) .
      lt_attr_value = me->parse_json( iv_objkey = ls_products-productid iv_json = lv_json ).
      out->write( lt_attr_value ).

* Read the json attributes for the workflow instance. Use the instance ID to get the instance context
      read table lt_attr_value into ls_attr_value with key id = 'id'.
      if sy-subrc = 0.

* Get the context of the instance by passing workflow instance id
        lv_json =  lo_scp_worflow_api->get_wf_instance_context(
                                              iv_wf_instance_id = ls_attr_value-value ) .
        lt_attr_value = me->parse_json( iv_objkey = ls_attr_value-value iv_json = lv_json ).
        out->write( lt_attr_value ).

* Update the context with an updated approvalStatus, just the approvalstatus nothing else
        out->write( lo_scp_worflow_api->update_wf_instance_context(
                                                  iv_wf_instance_id =  ls_attr_value-value
                                                  iv_context = '{ "approvalStatus": "approved" } ' ) ).

* Get the tasks of the instance by passing workflow instance id
        lv_json =  lo_scp_worflow_api->get_wf_task_instances(
                                                  iv_wf_instance_id = ls_attr_value-value ) .
        lt_attr_value = me->parse_json( iv_objkey = ls_attr_value-value iv_json = lv_json ).
        out->write( lt_attr_value ).

* Now read the first task of the workflow instance and update it.  Status Code 204 is success
        read table lt_attr_value into ls_attr_value with key id = 'id'.
        if sy-subrc = 0.

* Set the status of the task to COMPLETED
          out->write( lo_scp_worflow_api->update_wf_user_task_instance(
                                                    iv_task_instance_id = ls_attr_value-value
                                                    iv_status = 'COMPLETED'  ) ).

        endif.

      endif.

    endloop.

  endmethod.

  method parse_json.

* Horrible, horrible code. I can't wait to be able to update this method
* with how I wanted to implement it in the first place. Need APIs to be whitelisted.

    types: begin of ts_node,
             node_type type string,
             prefix    type string,
             name      type string,
             nsuri     type string,
             value     type string,
             value_raw type xstring,
           end of ts_node.
    data: ls_node type ts_node.
    data: lt_nodes like table of ls_node.
    data: lv_save_id type string.
    field-symbols: <ls_attr_value> type ts_attr_value.

    data(lv_json) = cl_abap_conv_codepage=>create_out( )->convert( iv_json ).
    data(lo_reader) = cl_sxml_string_reader=>create( lv_json ).

    try.
        do.
          data(ls_save_node) = ls_node.
          clear ls_node.
          data(lo_node) = lo_reader->read_next_node( ).
          if lo_node is initial.
            exit.
          endif.

          case lo_node->type.
            when if_sxml_node=>co_nt_element_open.
              data(lo_open_element) = cast if_sxml_open_element( lo_node ).
              data(lt_attributes)  = lo_open_element->get_attributes( ).

              loop at lt_attributes into data(lo_attribute).
                if lo_attribute->value_type = if_sxml_value=>co_vt_text.
                  ls_node-value = lo_attribute->get_value( ).
                  append initial line to rt_attr_value assigning <ls_attr_value>.
                endif.
              endloop.
              continue.
            when if_sxml_node=>co_nt_value.
              data(lo_value_node) = cast if_sxml_value_node( lo_node ).
              if lo_value_node->value_type = if_sxml_value=>co_vt_text.
                ls_node-value = lo_value_node->get_value( ).
* In the case where we don't have an objkey yet, we need to get this key from the ID attribute
* and spread that across the rest of the attributes as the object key.
                if iv_objkey is not initial.
                  <ls_attr_value>-objkey = iv_objkey.
                elseif ls_save_node-value = 'id'.
                  lv_save_id = ls_node-value.
                  <ls_attr_value>-objkey = ls_node-value.
                elseif lv_save_id is not initial.
                  <ls_attr_value>-objkey = lv_save_id.
                endif.
                <ls_attr_value>-id = ls_save_node-value.
                <ls_attr_value>-value = ls_node-value.
              endif.
              continue.
          endcase.
        enddo.
* Get rid of any blank lines.
        delete rt_attr_value where id is initial.
      catch cx_sxml_parse_error into data(lx_parse_error).
    endtry.

  endmethod.

endclass.
