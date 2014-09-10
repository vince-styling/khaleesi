$(function() {
    var context = 'div.toc_container ';
    var toc_selector = 'div#toc';

    $(context + toc_selector).tocify({
        context : 'div.description',
        selectors : 'h1,h2',
        highlightOnScroll : false,
        highlightDefault : false,
        smoothScroll : false,
        extendPage : false,
        hashGenerator : function(text, element) {
            return element.attr('id');
        }
    });

    $(window).scroll(function(){
        $(context).css({'top':10});
    });

    $(context + 'div#btn').click(function(){
        $(context + toc_selector).slideToggle('fast');
    });

    $(document).mouseup(function(e){
        var container = $(context);
        if (!container.is(e.target) && container.has(e.target).length === 0) {
            container.find(toc_selector).slideUp('fast');
        }
    });
});