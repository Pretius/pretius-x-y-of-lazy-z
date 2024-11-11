create or replace package body "PKG_COM_PRETIUS_XY_LAZY_Z" as

    /*
    * Plugin:   Pretius Lazy Pagination
    * Version:  24.1.1
    *
    * License:  MIT License Copyright 2024 Pretius Sp. z o.o. Sp. K.
    * Homepage: 
    * Mail:     apex-plugins@pretius.com
    * Issues:   https://github.com/Pretius/pretius-x-y-of-lazy-z/issues
    *
    * Author:   Matt Mulvaney
    * Mail:     mmulvaney@pretius.com
    * Twitter:  Matt_Mulvaney
    *
    */

  FUNCTION render(
    p_dynamic_action IN apex_plugin.t_dynamic_action,
    p_plugin         IN apex_plugin.t_plugin 
  ) RETURN apex_plugin.t_dynamic_action_render_result
  IS
    v_result              apex_plugin.t_dynamic_action_render_result; 
    l_plugs_row           APEX_APPL_PLUGINS%ROWTYPE;
    l_configuration_test  NUMBER DEFAULT 0;
    c_plugin_name         CONSTANT VARCHAR2(128) DEFAULT 'COM.PRETIUS.APEX_LAZY_PAGINATION';
    c_cache_rowcount      CONSTANT p_dynamic_action.attribute_01%TYPE DEFAULT p_dynamic_action.attribute_01;
    l_phrase              VARCHAR2(128) DEFAULT NULL;
    l_connector_word      VARCHAR2(32) DEFAULT NULL;
  BEGIN
    -- Debug
    IF apex_application.g_debug 
    THEN
      apex_plugin_util.debug_dynamic_action(p_plugin         => p_plugin,
                                            p_dynamic_action => p_dynamic_action);
    END IF;

    l_phrase := TRIM(apex_lang.message('WWV_RENDER_REPORT3.X_Y_OF_Z_2'));
    l_connector_word := SUBSTR(l_phrase, INSTR(l_phrase, ' ', -1) + 1);
    
    v_result.javascript_function := 
    apex_string.format(
    q'[function render() {
        plp.render({
            da: this,
            opt: { filePrefix: "%s",
                   ajaxIdentifier: "%s",
                   connectorWord: "%s",
                   cacheRowcount: "%s" }
        });
        }]',
    p_plugin.file_prefix,
    apex_plugin.get_ajax_identifier,
    l_connector_word,
    c_cache_rowcount
    );
 
    RETURN v_result;
  
  EXCEPTION
    WHEN OTHERS then
      htp.p( SQLERRM );
      return v_result;
  END render;

  FUNCTION ajax( p_dynamic_action IN apex_plugin.t_dynamic_action,
                   p_plugin         IN apex_plugin.t_plugin) 
      RETURN apex_plugin.t_dynamic_action_ajax_result
  IS
        -- Plugin attributes
        l_result     apex_plugin.t_dynamic_action_ajax_result;
        l_context               apex_exec.t_context;
        l_region_id             apex_application_page_regions.region_id%TYPE; 
        l_static_id             CONSTANT VARCHAR2(256) DEFAULT apex_application.g_x01;
        l_report_id             CONSTANT VARCHAR2(256) DEFAULT apex_application.g_x02;
        l_plpseq                CONSTANT NUMBER DEFAULT apex_application.g_x03;
        l_plpcs                 CONSTANT NUMBER DEFAULT apex_application.g_x04;
        l_row_count             NUMBER DEFAULT NULL;
        l_outer_sql_c           CONSTANT VARCHAR2(128) DEFAULT 'SELECT COUNT(*) CNT FROM #APEX$SOURCE_DATA#'; 
        l_app_id_c              CONSTANT apex_application_page_regions.application_id%TYPE DEFAULT V('APP_ID');
        l_app_page_id_c         CONSTANT apex_application_page_regions.page_id%TYPE DEFAULT V('APP_PAGE_ID');
  BEGIN 
    -- Fetch the region ID based on static_id, app_id, and page_id
    BEGIN
        SELECT region_id 
          INTO l_region_id
          FROM apex_application_page_regions 
         WHERE application_id = l_app_id_c
           AND page_id = l_app_page_id_c
           AND NVL(static_id, 'R' || region_id) = l_static_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Raise a meaningful exception if no region is found
            raise_application_error(-20001, 'Region not found for static ID ' || l_static_id);
        WHEN TOO_MANY_ROWS THEN
            -- Handle case where more than one region is found
            raise_application_error(-20002, 'Multiple regions found for static ID ' || l_static_id);
        WHEN OTHERS THEN
            -- Log the error and re-raise it for other unexpected issues
            raise_application_error(-20003, 'Unexpected error occurred: ' || SQLERRM);
    END;

    -- Open the query context using APEX_EXEC
    l_context := apex_region.open_query_context (
          p_page_id      => l_app_page_id_c,
          p_region_id    => l_region_id,
          p_component_id => l_report_id, 
          p_outer_sql    => l_outer_sql_c );

    -- -- Fetch and process rows using APEX_EXEC
    WHILE apex_exec.next_row(l_context) LOOP
        l_row_count := apex_exec.get_number(l_context, 1);
    END LOOP;

    -- Return JSON data with the row count
    apex_json.open_object;
    apex_json.write('data', l_row_count);
    apex_json.write('reportid', l_report_id);
    apex_json.write('plpseq', l_plpseq);
    apex_json.write('plpcs', l_plpcs);
    apex_json.close_object;

    RETURN l_result;

  EXCEPTION
      -- Catch-all block for any unhandled exceptions
      WHEN OTHERS THEN
          -- Log or handle the error if necessary
          raise_application_error(-20004, 'An error occurred during the AJAX processing: ' || SQLERRM);
  END ajax;

end "PKG_COM_PRETIUS_XY_LAZY_Z";
/