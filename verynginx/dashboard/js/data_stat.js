var data_stat = new Object();

data_stat.latest_data = null;

data_stat.url_table = null;
data_stat.collect_table = null;

data_stat.search = function( s ){
    if( data_stat.url_table != null ){
        data_stat.url_table.search( s ).draw();
    }
    
    if( data_stat.collect_table != null ){
        data_stat.collect_table.search( s ).draw();
    }

}

data_stat.tab_switch = function ( item ) {
    // 标签切换文字变化
    if( $(item).attr('id') == 'summary_data_all' ){
        $("#def_btn").html("All<span class=\"caret\"></span>");
    }else{
        $("#def_btn").html("Temporary<span class=\"caret\"></span>");
    } 
    
    data_stat.get_data();
}

data_stat.make_sure_have_table = function(){

    if( data_stat.url_table == null || data_stat.collect_table == null ){
        data_stat.get_data();
    }
}

data_stat.fill_data_info_table = function( data_type, data_dict ){

    var table_id = null;
    if(data_type == 'collect'){
        table_id = 'matched_details';
    }else if( data_type == 'uri'){
        table_id = 'unmatched_details';
    }else{
        throw new Error("unknown data_type");
        return;
    }

    $('#' + table_id).html(""); // 动态生成表格前将表格清空

    var url_index = 1;
    for (var key in data_dict ) {
        var data_group = data_dict[key];

        // 计算访问成功率
        var success_count = 0;
        var total_count = 0;
        for( var status_code in data_group['status'] ){
            var this_status_count = data_group['status'][status_code];
            if( parseInt( status_code ) < 400 ){
                success_count += this_status_count;
            }
            total_count += this_status_count;
        }
        
        var success_rate = (success_count / total_count) * 100;
        var count = parseInt(data_dict[key].count);
        var size = parseFloat(data_dict[key].size);
        var avg_size = size / count;
        var time = parseFloat(data_dict[key].time);
        var avg_time = time / count;

        // 动态增加每一列关于各URL/URI的详细访问信息
        var dyn_tab =  "<tr><td >" + url_index + "</td>" +
                       "<td>" + util.html_encode(key) + "</td>" +
                       "<td>" + count + "</td>" +
                       "<td>" + size + "</td>" +
                       "<td>" + avg_size.toFixed(2) + "</td>" +
                       "<td>" + success_rate.toFixed(2) + '% <button detail_type="' + data_type + '" detail_key="' + util.html_encode(key) + '" class="btn vn_summary_detail_btn btn-xs">Details</button> </td>' +
                       "<td>" + time.toFixed(3) + "</td>" +
                       "<td>" + avg_time.toFixed(3) + "</td></tr>";

        $('#' + table_id).append(dyn_tab);

        url_index++; // 增加访问序列
    }
}


data_stat.get_data = function () {

    var url_short = "./summary?type=short";
    var url_long  = "./summary?type=long";
    var data_url;

    // 判断数据量
    if ($("#def_btn").text() == 'All') {
        data_url = url_long;
        $("#summary_type_note").css("display", "none");
    } else {
        data_url = url_short;
        $("#summary_type_note").css("display", "inline-block");
    };

    $.ajax({
        type: "GET",
        url: data_url,
        // url: "/verynginx/summary?type=long",
        data_Type: "json",

        success: function (json_data) {
            data_stat.latest_data = json_data;
            var data_uri = json_data['uri'];
            var data_collect = json_data['collect'];

            data_stat.json_data = json_data;

            if( data_stat.url_table != null ){
                data_stat.url_table.clear().destroy();
            }
            
            if( data_stat.collect_table != null ){
                data_stat.collect_table.clear().destroy();
            }
            
            data_stat.fill_data_info_table( 'uri', data_uri );
            data_stat.fill_data_info_table( 'collect', data_collect );

            // 添加表格排序
            data_stat.url_table = $('#summary_unmatched_table').DataTable( {
                                autoWidth: false, // 设置表格自动适配宽度
                                scrollY:    "500px",
                                scrollCollapse: true,
                                paging: false, // 去掉页头页脚信息
                                "stripeClasses": [], // 去掉斑马色
                                renderer: true,
                                searching: true, // 增加过滤功能
                                "order": [[ 0, "asc" ]] // 载入时默认使用index升序排列
                            } );

            data_stat.collect_table = $('#summary_matched_table').DataTable( {
                                autoWidth: false, // 设置表格自动适配宽度
                                scrollY:    "500px",
                                scrollCollapse: true,
                                paging: false, // 去掉页头页脚信息
                                "stripeClasses": [], // 去掉斑马色
                                renderer: true,
                                searching: true, // 增加过滤功能
                                "order": [[ 0, "asc" ]] // 载入时默认使用index升序排列
                            } );

            $('#summary_unmatched_table tbody').unbind('mouseover');
            $('#summary_unmatched_table tbody').unbind('mouseout');

            $('#summary_unmatched_table tbody').on('mouseover', data_stat.detail_btn_mouse_out   );
            $('#summary_unmatched_table tbody').on('mouseout', data_stat.detail_btn_mouse_over  );
        }
    });   
}


data_stat.popover_item = null;

data_stat.clean_popover = function(){
    if( data_stat.popover_item != null ){
        data_stat.popover_item.popover('destroy');
        data_stat.popover_item.popover_item = null;
    }
}

data_stat.detail_btn_mouse_over = function( e ){
    var target = $(e.relatedTarget);
    if( target.hasClass('vn_summary_detail_btn') == false )
        return;
   
    data_stat.clean_popover();

    var detail_key = target.attr('detail_key');
    var detail_type = target.attr('detail_type');

    var response_status = null;
    var response_count = null;  
    if( detail_type == 'uri' ){
        response_status = data_stat.latest_data['uri'][detail_key]['status']; 
        response_count = data_stat.latest_data['uri'][detail_key]['count'];  
    }else{
        response_status = data_stat.latest_data['collect'][detail_key]['status'];
        response_count = data_stat.latest_data['collect'][detail_key]['count'];  
    }

    var content = "<table>";
    var status_list = Object.keys(response_status);
    for( var i=0; i<status_list.length; i++ ){
        var status_code = status_list[i];
        var rate = (100 * response_status[status_code] / response_count).toFixed(2);
        content += "<tr><td><span class='label label-info'>"+status_code+"</span></td>" + 
                       "<td class='vn_summary_detail_popover_count'>" + response_status[status_code] + "</td>" + 
                       "<td class='vn_summary_detail_popover_rate'>" + rate + "%</td></tr>";
    }

    content += "</table>";
    target.popover({
        animation : false,
        html : true,
        placement : 'right', //placement of the popover. also can use top, bottom, left or right
        title : 'Response Details', //this is the top title bar of the popover. add some basic css
        content : content, //this is the content of the html box. add the image here or anything you want really.
    })
    target.popover('show');
    data_stat.popover_item = target;
}

data_stat.detail_btn_mouse_out = function( e ){
    if( $(e.relatedTarget).hasClass('vn_summary_detail_btn') == true ){
        data_stat.clean_popover();
    }
}


