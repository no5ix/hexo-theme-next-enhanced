{% if theme.local_search.enable %}
  <script type="text/javascript">

    var is_load_xml_finished = 0;

    var searchFunc = function (path, search_id, content_id) {
      // 0x00. environment initialization
      'use strict';

      var $input = document.getElementById(search_id);
      var $resultContent = document.getElementById(content_id);
      // var datas = [];

      /* loading css1 : Dot Css Loader*/
      var DotLoader = "<div class='loader'>Loading...</div>";

      /* loading css2 : Pure Css Loader - Square */
      var SquareLoader = 
        "<div class='loader'>" +
          "<div class='square' ></div>" +
          "<div class='square'></div>" +
          "<div class='square last'></div>" +
          "<div class='square clear'></div>" +
          "<div class='square'></div>" +
          "<div class='square last'></div>" +
          "<div class='square clear'></div>" +
          "<div class='square '></div>" +
          "<div class='square last'></div>" +
        "</div>";

      var ProgressBar = 
          "<div class='progress-bar'>" +
            "<div class='progress-bar-charge'></div>" +
          "</div>";

      var str = "";
      var keywords = [];
      var temp_keyword = "";

      // 是否为第一个字母被键入的标志位
      var first_char_flag = 0;

      // 因为在移动设备上, 点击搜索之后会 scroll 到页面顶部, 所以需要记录之前的页面x, y坐标值, 以便于搜索完点击 close 按钮之后 scroll 回原来的页面坐标值.
      var last_page_x = 0;
      var last_page_y = 0;

      var local_search_tips = 
            "<span class='local-search-empty'>" + "第一次搜索可能较慢, 先思考一个经典算法问题, 跳台阶:" + "</span>" +
            "<span class='local-search-empty'>" + "一只青蛙一次可以跳上1级台阶，也可以跳上2级。求该青蛙跳上一个6级的台阶总共有多少种跳法?n级呢?" + "</span>";

      function CloseLocalSearch()
      {
        first_char_flag = 0;

        $('#local-search-input').val('');
        $('#local-search-close').hide();

        // $('.local-search-result-cls ul li').velocity('stop').velocity('transition.slideDownOut', 200);

        $('#' + content_id).attr("headroom_special_attr","true"); 
        
        if (isMobile())
        {
          // $('body').scrollTop(last_page_y);  // scrollTop 有兼容性问题
          scrollTo(last_page_x, last_page_y);

          $('#' + content_id).hide();
        }
        else
        {
          $('#' + content_id).velocity('stop').velocity( 'transition.bounceUpOut', 200 );
        }

        // $('#' + content_id).velocity('stop').velocity( isMobile() ? 'transition.fadeOut' : 'transition.bounceUpOut', {
        //   // delay: isMobile() ? 50 : 0,
        //   duration: isMobile() ? 500 : 200,
        //   // begin: function() { 
        //   //   if (isMobile())
        //   //   {
        //   //     $('body').scrollTop(last_page_y);
        //   //   } 
        //   // }
        //   complete: function () {
        //     if (isMobile())
        //     {
        //       if (last_page_y < 20000)
        //       {
        //         $('body').velocity('scroll', { offset: last_page_y+"px", duration: last_page_y < 10000 ? 1000 : 2000 });
        //       }
        //       else
        //       {
        //         $('body').scrollTop(last_page_y);
        //       }
        //       // $('body').velocity('scroll');

        //       // $('html,body').animate({
        //       //   scrollTop: last_page_y
        //       // },400);
        //       // $('body').velocity('transition.slideDownIn', 1000);
        //       // $('body').velocity('scroll', { offset: last_page_y+"px", duration: document.body.scrollHeight < 20000 ? 1500 : 3000 });
        //     }
        //   }
        // });
      }

      function handleSearch()
      {
        if (keywords.length <= 0) {
          return;
        }
        $resultContent.innerHTML = "";
        $('#local-search-close').show();

        // 0x04. perform local searching
        if (is_load_xml_finished == 0)
        {
          $resultContent.innerHTML = 
            "<ul class='local-search-empty-ul'>" + 
            local_search_tips +
            ProgressBar;
        }
        else
        {
          // Retrieve the object from local storage
          var xml_resp = retrieve_search_xml()

          xml_resp.forEach(function (data) {
          // datas.forEach(function (data) {
            var isMatch = true;
            var content_index = [];
            if (!data.title || data.title.trim() === '') {
              data.title = "Untitled";
            }
            var is_encrypted = data.encrypted.trim() == '1'
            var is_sensitive = CONFIG.local_search.sensitive_word && data_content.indexOf(CONFIG.local_search.sensitive_word) >= 0
            var orig_data_title = data.title.trim();
            var data_title = orig_data_title.toLowerCase();
            var orig_data_content = data.content.trim().replace(/<[^>]+>/g, "");
            var data_content = orig_data_content.toLowerCase();
            var data_url = decodeURIComponent(data.url);
            var index_title = -1;
            var index_content = -1;
            var first_occur = -1;
            // only match artiles with not empty contents
            if (data_content !== '') {
              keywords.forEach(function (keyword, i) {
                index_title = data_title.indexOf(keyword);
                index_content = (is_sensitive || is_encrypted) ? -1 : data_content.indexOf(keyword);

                if (index_title < 0 && index_content < 0) {
                  isMatch = false;
                } else {
                  if (index_content < 0) {
                    index_content = 0;
                  }
                  if (i == 0) {
                    first_occur = index_content;
                  }
                  // content_index.push({index_content:index_content, keyword_len:keyword_len});
                }
              });
            } else {
              isMatch = false;
            }
            // 0x05. show search results
            if (isMatch) {
              var content = orig_data_content;
              if (first_occur >= 0) {
                var match_content = "";
                if (!is_sensitive && !is_encrypted)
                {
                  // cut out 100 characters
                  var start = first_occur - 20;
                  var end = first_occur + 80;

                  if (start < 0) {
                    start = 0;
                  }

                  if (start == 0) {
                    end = 100;
                  }

                  if (end > content.length) {
                    end = content.length;
                  }

                  match_content = content.substr(start, end);
                }

                // highlight all keywords
                var regS = "";
                if (match_content != "")
                {
                  keywords.forEach(function (keyword) {
                    regS = new RegExp(keyword, "gi");
                    match_content = match_content.replace(regS, "<b class=\"search-keyword\">" + keyword + "</b>");
                    orig_data_title = orig_data_title.replace(regS, "<b class=\"search-keyword\">" + keyword + "</b>");
                  });
                }
                else
                {
                  keywords.forEach(function (keyword) {
                    regS = new RegExp(keyword, "gi");
                    orig_data_title = orig_data_title.replace(regS, "<b class=\"search-keyword\">" + keyword + "</b>");
                  });
                }
                str += "<li><a href='" + data_url + "' class='search-result-title' target='_blank'>" + orig_data_title + "</a>";
                str += "<p class=\"search-result\">" + match_content + "...</p>"
              }
              str += "</li>";
            }
          });

          str += "</ul>";
          if (str.indexOf('<li>') === -1) {
            return $resultContent.innerHTML = 
              "<ul class='local-search-empty-ul'><span class='local-search-empty'>找不到, 换个搜索关键字试一哈.<span></ul>";
          }
          $resultContent.innerHTML = str;
        }
      }

      $input.addEventListener('input', function () {
        // 0x03. parse query to keywords list
        str = '<ul class=\"search-result-list\">';
        temp_keyword = this.value.trim();
        if (temp_keyword.length <= 0) {
          CloseLocalSearch();
          return;
        }

        keywords = temp_keyword.toLowerCase().split(/[\s\-]+/);
        handleSearch();

        // 当用户键入第一个字母的时候的动画处理逻辑 : 
        // 当 first_char_flag 为 0 的时候, 
        // 要播放一个动画
        if (first_char_flag == 0)
        {
            // $('body').scrollTop(0);
          if (isMobile())
          {
            last_page_x = window.pageXOffset;
            last_page_y = window.pageYOffset;
            // $('body').scrollTop(0);
            scrollTo(0,0);

          }
          first_char_flag = 1;
          $('#' + content_id).removeAttr("headroom_special_attr");
          
          $('#' + content_id).velocity('stop').velocity('transition.slideDownIn', 300);

          $('.local-search-result-cls ul li').velocity('stop').velocity('transition.slideDownIn', 1000);
        }
      });


      var local_search_xml_data = localStorage.getItem('local_search_xml_data');
      if (!local_search_xml_data) {
        $.ajax({
          // 0x01. load xml file
          url: path,
          dataType: "xml",
          success: function (xmlResponse) {
            store_search_xml(xmlResponse);

            // setTimeout(function(){
            //   is_load_xml_finished = 1;

            //   handleSearch();
            //   $('.local-search-result-cls ul li').velocity('stop').velocity('transition.slideDownIn', 800);
            // }, 2000);
            
            // is_load_xml_finished = 1;

            handleSearch();
            $('.local-search-result-cls ul li').velocity('stop').velocity('transition.slideDownIn', 800);
          }
        });
      }

      $(document).on('click', '#local-search-close', function() {
        CloseLocalSearch();
      });

      $(document).keyup(function(event){
        switch(event.keyCode) {
          case 27:
            // alert("ESC");
            CloseLocalSearch();
        }
      });

      // $(document).on('blur', '#local-search-input', function(e) {
      //   // console.log(document.activeElement.getAttribute('class'));
        
      //   if (isMobile() == false)
      //   {
      //     CloseLocalSearch();
      //   }
      // });
    }

    function isMobile() {
      // console.log(document.body.clientWidth);
      return document.body.clientWidth < 768

      // var userAgent = window.navigator.userAgent;

      // var isiPad = userAgent.match(/iPad/i) !== null;
      // var mobileUA = [
      //   'iphone', 'android', 'phone', 'mobile',
      //   'wap', 'netfront', 'x11', 'java', 'opera mobi',
      //   'opera mini', 'ucweb', 'windows ce', 'symbian',
      //   'symbianos', 'series', 'webos', 'sony',
      //   'blackberry', 'dopod', 'nokia', 'samsung',
      //   'palmsource', 'xda', 'pieplus', 'meizu',
      //   'midp' ,'cldc' , 'motorola', 'foma',
      //   'docomo', 'up.browser', 'up.link', 'blazer',
      //   'helio', 'hosin', 'huawei', 'novarra',
      //   'coolpad', 'webos', 'techfaith', 'palmsource',
      //   'alcatel', 'amoi', 'ktouch', 'nexian',
      //   'ericsson', 'philips', 'sagem', 'wellcom',
      //   'bunjalloo', 'maui', 'smartphone', 'iemobile',
      //   'spice', 'bird', 'zte-', 'longcos',
      //   'pantech', 'gionee', 'portalmmm', 'jig browser',
      //   'hiptop', 'benq', 'haier', '^lct',
      //   '320x320', '240x320', '176x220'
      // ];
      // var pattern = new RegExp(mobileUA.join('|'), 'i');

      // return !isiPad && userAgent.match(pattern);
    }

    function store_search_xml(xmlResponse) {
        datas = $("entry", xmlResponse).map(function () {
          return {
            title: $("title", this).text(),
            content: $("content", this).text(),
            url: $("url", this).text(),
            encrypted: $("encrypted", this).text(),
          };
        }).get();
        // Put the object into storage
        localStorage.setItem('local_search_xml_data', JSON.stringify(datas));
        is_load_xml_finished = 1;

        console.log("store search.xml finished.");
    }

    function ajax_store_search_xml() {
      $.ajax({
        url: "/search.xml",
        dataType: "xml",
        success: function (xmlResponse) {
            store_search_xml(xmlResponse);
        }
      });
    }

    function retrieve_search_xml() {
        // Retrieve the object from local storage
        var retrievedObject = localStorage.getItem('local_search_xml_data');
        var xml_resp = JSON.parse(retrievedObject)
        return xml_resp
    }

    var getSearchFile = function(){
      var path = "/search.xml";
      var local_search_result_name = isMobile() ? "local-search-result-mobile" : "local-search-result-pc";
      searchFunc(path, 'local-search-input', local_search_result_name);
    }

    var local_search_xml_data = localStorage.getItem('local_search_xml_data');
    if (local_search_xml_data) {
      is_load_xml_finished = 1;
      console.log("load search.xml finished.");
    }
    var last_use_local_search_date = localStorage.getItem('last_use_local_search_date');
    var curDate = new Date();
    // 只有在 localStorage 没有 search.xml数据或者 距离上次使用local search已经超过一天了才去取search.xml
    // 节省流量
    if (last_use_local_search_date != curDate.getDate() || !local_search_xml_data) {
      // preload search.xml
      ajax_store_search_xml();
    }

    localStorage.setItem('last_use_local_search_date', curDate.getDate());
    

  </script>
{% endif %}
