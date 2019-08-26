var blackip = new Object();

blackip.blackip_vm = null; 
blackip.verynginx_blackip = {};

blackip.original_blackip_json = null;


blackip.get_blackip = function(){
    $.get("./blackip",function(data,status){
        blackip.original_blackip_json = JSON.stringify( data , null, 2);
        blackip.verynginx_blackip = data; 

        if( blackip.blackip_vm != null ){
            blackip.blackip_vm.$set( 'blackip_now', data);
            dashboard.notify("Reread blackip success");
            return;
        }

        blackip.blackip_vm = new Vue({
            el: '#verynginx_blackip',
            data: {
                'blackip_now':blackip.verynginx_blackip,
            },
            computed : {
                all_blackip_json: function(){
                    return JSON.stringify( this.blackip_now , null, 2);
                }
            },
        });

    }); 
}

blackip.get_blackip()
