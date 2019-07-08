class zcl_scp_workflow_api definition
        public final create public .

  public section.

    methods: constructor
      importing iv_url      type string
                iv_user     type string
                iv_password type string.

    methods: get_wf_definition
      importing iv_definition_id  type string
      returning value(r_response) type string.

    methods: get_wf_definition_model
      importing iv_definition_id  type string
      returning value(r_response) type string.

    methods: get_wf_instances_by_status
      importing iv_definition_id  type string
                iv_status         type string
      returning value(r_response) type string.

    methods: get_wf_instance_by_businesskey
      importing iv_businesskey    type string
      returning value(r_response) type string.

    methods: get_wf_instance_context
      importing iv_wf_instance_id type string
      returning value(r_response) type string.

    methods: get_wf_task_instances
      importing iv_wf_instance_id type string
      returning value(r_response) type string.

    methods: create_wf_instance
      importing iv_definition_id  type string
                iv_context        type string
      returning value(r_response) type string.

    methods: update_wf_instance_context
      importing iv_wf_instance_id type string
                iv_context        type string
      returning value(r_response) type string.

    methods: update_wf_user_task_instance
      importing iv_task_instance_id type string
                iv_status           type string
      returning value(r_response)   type string.

    methods: delete_wf_instances
      importing iv_wf_instance    type string
      returning value(r_response) type string.

    methods: delete_wf_definition
      importing iv_definition_id  type string
      returning value(r_response) type string.

  protected section.
  private section.

    data: gv_url type string.
    data: gv_user type string.
    data: gv_password type string.

    methods: execute_workflow_request
      importing iv_uri_path       type string
                iv_http_action    type if_web_http_client=>method
                  default if_web_http_client=>get
                iv_request_text   type string optional
      returning value(r_response) type string
      raising   cx_web_message_error.

endclass.

class zcl_scp_workflow_api implementation.

  method constructor.
    gv_url = iv_url.
    gv_user = iv_user.
    gv_password = iv_password.

  endmethod.

  method get_wf_definition.

    r_response = execute_workflow_request( |workflow-definitions/{ iv_definition_id }| ).

  endmethod.

  method get_wf_definition_model.

    r_response = execute_workflow_request( |workflow-definitions/{ iv_definition_id }/model| ).

  endmethod.

  method get_wf_instances_by_status.

    r_response = execute_workflow_request( |workflow-instances?{ iv_definition_id }&status={ iv_status }| ).

  endmethod.

  method get_wf_instance_by_businesskey.

    r_response = execute_workflow_request( |workflow-instances?businessKey={ iv_businesskey }| ).

  endmethod.

  method get_wf_instance_context.

    r_response = execute_workflow_request( |workflow-instances/{ iv_wf_instance_id }/context| ).

  endmethod.

  method get_wf_task_instances.

    r_response = execute_workflow_request( |task-instances?workflowInstanceId={ iv_wf_instance_id }| ).

  endmethod.

  method create_wf_instance.

    r_response = execute_workflow_request(
                        iv_uri_path = |workflow-instances|
                        iv_http_action = if_web_http_client=>post
                        iv_request_text = |\{ "definitionId": "{ iv_definition_id }", "context": {  iv_context } \}| ).

  endmethod.

  method update_wf_instance_context.

    r_response = execute_workflow_request(
                        iv_uri_path = |workflow-instances/{ iv_wf_instance_id }/context|
                        iv_http_action = if_web_http_client=>patch
                        iv_request_text = iv_context ).

  endmethod.

  method update_wf_user_task_instance.

    r_response = execute_workflow_request(
                        iv_uri_path = |task-instances/{ iv_task_instance_id }|
                        iv_http_action = if_web_http_client=>patch
                        iv_request_text =  |\{ "context": \{ \}, "status": "{ iv_status }" \}| ).

  endmethod.

  method delete_wf_instances.

    r_response = execute_workflow_request(
                        iv_uri_path = |workflow-instances|
                        iv_http_action = if_web_http_client=>patch
                        iv_request_text =  |[ \{ "id": "{ iv_wf_instance }",  "deleted": true  \} ]| ).

  endmethod.

  method delete_wf_definition.

    r_response = execute_workflow_request(
                        iv_uri_path = |workflow-definitions/{ iv_definition_id }|
                        iv_http_action = if_web_http_client=>delete ).

  endmethod.

  method execute_workflow_request.

    try.

        data(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination(
                                 i_destination = cl_http_destination_provider=>create_by_url( gv_url ) ).
        data(lo_request) = lo_http_client->get_http_request( ).

        lo_request->set_authorization_basic( i_username = gv_user i_password = gv_password ).

        if iv_http_action <> if_web_http_client=>get.
          lo_request->set_header_field( i_name = 'X-CSRF-Token' i_value = 'Fetch' ).
          lo_request->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).
          data(lo_response) = lo_http_client->execute( i_method = if_web_http_client=>get ).
          lo_http_client->set_csrf_token( ).
        endif.

        lo_request->set_uri_path( i_uri_path = gv_url && iv_uri_path ).
        if iv_request_text is supplied.
          lo_request->set_text( iv_request_text ).
        endif.

        data ls_status type if_web_http_response=>http_status.
        case iv_http_action.
          when if_web_http_client=>get or if_web_http_client=>post.
            r_response = lo_http_client->execute( i_method = iv_http_action )->get_text( ).
          when if_web_http_client=>patch or if_web_http_client=>delete.
            lo_response = lo_http_client->execute( i_method = iv_http_action ).
            ls_status = lo_response->get_status( ).
            r_response = |Response is: { ls_status-code } { ls_status-reason }.| .
          when others.
            r_response = |Response is: 405 Method Not Allowed.| .
        endcase.
        lo_http_client->close( ).

      catch cx_http_dest_provider_error cx_web_http_client_error into data(lx_error).
        r_response =  lx_error->get_text( ).
    endtry.

  endmethod.

endclass.
