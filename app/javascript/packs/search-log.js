$( document ).on('turbo:load', function() {
    handleRawJsonToggle();

    function handleRawJsonToggle() {
        $('.show-raw-json').click(function(e){
            var id = e.currentTarget.id;
            var target = $('#raw-json-' + id);
            var link = $("a#" + id).get()[0];
            $(target).toggle(400);
            toggleLinkName(link);
        });
    }
    function toggleLinkName(link){
        link.innerHTML = (link.innerHTML === 'Show Raw JSON') ? 'Hide Raw JSON' : 'Show Raw JSON' ;
    }
})

