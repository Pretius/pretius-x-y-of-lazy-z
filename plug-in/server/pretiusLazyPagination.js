/*
* Plugin:   Pretius Lazy Pagination
* Version:  24.1.1
*
* License:  MIT License Copyright 20224 Pretius Sp. z o.o. Sp. K.
* Homepage: 
* Mail:     apex-plugins@pretius.com
* Issues:   https://github.com/Pretius/pretius-x-y-of-lazy-z/issues
*
* Author:   Matt Mulvaney
* Mail:     mmulvaney@pretius.com
* Twitter:  Matt_Mulvaney
*
*/

var plp = (function () {
    "use strict";


    var render = function render(options) {
        var debugPrefix = 'Pretius Lazy Pagination: ';
        apex.debug.info(debugPrefix + 'render', options);

        $.each(options.da.affectedElements, function (i, cEl) {

            $(cEl).attr('plpconnector', options.opt.connectorWord);
            var regionId = $(cEl).attr('id');
            
            var irInstance = $(cEl).find('#' + regionId + '_ir').interactiveReport("instance");

            if ( irInstance === undefined ) {
                ajaxErrorHandler(options, '', '', 'Element ' + regionId + ' is not an Interactive Report');
                return;
            }

            if (isXYpaginated(cEl)) {

                var reportId = apex.item(regionId + '_report_id').getValue();
                var plpcount = $(cEl).attr('plpcount' + reportId);

                var plpcs = $(cEl).attr('plpcs' + reportId);
                var currentPlpCs = simpleChecksum($('#' + regionId +'_control_panel').text());

                if ( ( options.opt.cacheRowcount == 'N' ) || 
                   ( ( options.opt.cacheRowcount == 'Y' ) &&
                      ( plpcs !== currentPlpCs || (  plpcs === currentPlpCs && ( plpcount === undefined || plpcount === '') ) ) ) ) {

                     $(cEl).attr('plpcount' + reportId, '');

                    // Increment sequence
                    var currentSeq = $(cEl).attr('plpseq' + reportId);
                    var newSeq = (isNaN(parseInt(currentSeq)) ? 0 : parseInt(currentSeq)) + 1;
                    $(cEl).attr('plpseq' + reportId, newSeq);


                    $(cEl).attr('plpcs' + reportId, currentPlpCs);

                    addGrammar(cEl);

                    apex.server.plugin(options.opt.ajaxIdentifier, {
                        x01: regionId,
                        x02: reportId,
                        x03: newSeq,
                        x04: currentPlpCs
                    }, {
                        // Success function
                        success: function (data) {

                            var currentReportId = apex.item(regionId + '_report_id').getValue();
                            var currentSeq = $(cEl).attr('plpseq' + currentReportId);
                            var currentCS = simpleChecksum($('#' + regionId +'_control_panel').text());

                            if (data.reportid == currentReportId && data.plpseq == currentSeq && data.plpcs == currentCS) {

                                var rowCount = data.data;
                                rowCount = apex.locale.formatNumber(rowCount, "FM999G999G999G999G999G999G999G999G999")

                                addGrammar(cEl, rowCount);
                            }

                            if (data.plpseq == currentSeq ) {
                                //  stashCount
                                $(cEl).attr('plpcount' + data.reportid, rowCount);
                            }
                        },
                        // Error function
                        error: function (pData, pErr, pErrorMessage) {
                            ajaxErrorHandler(options, pData, pErr, pErrorMessage);
                        }
                    });

                } else {
                    addGrammar(cEl, plpcount);
                }
            } else {
                if ( $(cEl).find('.a-IRR-noDataMsg').length == 0 && irInstance.needsLazyLoading === false ) {
                 ajaxErrorHandler(options, '', '', 'Region ' + regionId + ' is not X of Y Paginated');
                }
            }


        });

    };

    function addGrammar(cEl, val) {
        $(cEl).find('.plp_pagination').remove();

        var string = '<span class="plp_pagination plp_pagination_gr_label">&nbsp;' + $(cEl).attr('plpconnector') + '&nbsp;'
            + (val ? val : '') + '</span>';
        $(cEl).find('.a-IRR-pagination-label').append(string);

        // Call addSpinner(cEl) only if val is truthy
        if (!val) {
            addSpinner(cEl);
        }
    }

    function simpleChecksum(str) {
        let checksum = 0;
        for (let i = 0; i < str.length; i++) {
            checksum += str.charCodeAt(i);
        }
        return checksum.toString();
    }

    function isXYpaginated(cEl) {
        // Get the text of the element
        var text = $(cEl).find('.a-IRR-pagination-label:first').text().trim();

        // Define a regex pattern to match the required format
        var pattern = /^\d{1,3}(?:,\d{3})?\s*-\s*\d{1,3}(?:,\d{3})?$/;

        // Test the text against the pattern
        return pattern.test(text);
    }

    function addSpinner(cEl) {
        var string = '<span aria-hidden="true" class="plp_pagination plp_pagination_spinner fa fa-circle-7-8 fa-anim-spin u-alignBaseline"></span>';
        $(cEl).find('.a-IRR-pagination-label').append(string);
    }


    var ajaxErrorHandler = function ajaxErrorHandler(options, pData, pErr, pErrorMessage) {

        // Remove possible Error State Spinner
        $.each(options.da.affectedElements, function (i, cEl) {
            $(cEl).find('.plp_pagination').remove();
        });

        apex.message.clearErrors();
        apex.message.showErrors([{
            type: "error",
            location: ["page"],
            message: '[Pretius Lazy Pagination] ' + pErrorMessage + '<br>Please check browser console.',
            unsafe: false
        }]);

        apex.debug.log(pData, pErr, pErrorMessage);
    }

    return {
        render: render,
        ajaxErrorHandler: ajaxErrorHandler
    }

})();