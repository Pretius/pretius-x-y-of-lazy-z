create or replace package "PKG_COM_PRETIUS_XY_LAZY_Z" as

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
  ) RETURN apex_plugin.t_dynamic_action_render_result;

  FUNCTION ajax( p_dynamic_action IN apex_plugin.t_dynamic_action,
                   p_plugin         IN apex_plugin.t_plugin) 
  RETURN apex_plugin.t_dynamic_action_ajax_result;

end "PKG_COM_PRETIUS_XY_LAZY_Z";
/