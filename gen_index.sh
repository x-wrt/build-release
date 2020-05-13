OUT=index.html
cp $OUT $OUT.old 2>/dev/null
echo -n >$OUT
cat <<EOF >>$OUT
<html><head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <style type="text/css">
  html, body {
    margin: 0;
    padding: 0;
    height: 100%;
  }
  body {
    color: #333;
    padding-top: 2em;
    font-family: Helvetica,Arial,sans-serif;
    width: 90%;
    min-width: 700px;
    max-width: 1100px;
    margin: auto;
    font-size: 120%;
    background-color: #ddd;
  }
  h1 {
    font-size: 120%;
    line-height: 1em;
  }
  h2 {
    font-size: 100%;
    line-height: 1em;
  }
  table {
    width: 100%;
    box-shadow: 0 0 0.5em #999;
    margin: 0;
    border: none !important;
    margin-bottom: 2em;
    border-collapse: collapse;
    border-spacing: 0;
  }
  th {
    background: #000;
    background: -webkit-linear-gradient(top, #444, #000);
    background: -moz-linear-gradient(top, #444, #000);
    background: -ms-linear-gradient(top, #444, #000);
    background: -o-linear-gradient(top, #444, #000);
    background: linear-gradient(top, #444, #000);
    font-size: 14px;
    line-height: 24px;
    border: none;
    text-align: left;
    color: #fff;
  }
//  tr {
//    background: rgba(255, 255, 255, 0.8);
//  }
  tr:hover {
    background: rgba(255, 255, 127, 0.7);
  }
  .tr0 td {
    background: rgba(255, 255, 255, 0.8);
  }
  .tr1 td {
    background: rgba(255, 255, 255, 0.3);
  }
  p, th, td {
    font-size: 14px;
  }
  th, td {
    height: 24px;
    vertical-align: middle;
    white-space: nowrap;
    padding: 0.2em 0.5em;
    border: 0px solid #ccc;
  }
  a:link, a:visited {
    color: #337ab7;
    font-weight: bold;
    text-decoration: none;
  }
  a:hover, a:active, a:focus {
    color: #23527c;
    text-decoration: underline;
  }
  .s {
    text-align: right;
    width: 15%;
  }
  .d {
    text-align: center;
    width: 15%;
  }
  .sh {
    font-family: monospace;
  }
  </style>
<script>
var _hmt = _hmt || [];
(function() {
  var hm = document.createElement("script");
  hm.src = "https://hm.baidu.com/hm.js?f06f5fc49fb52ef31f67adeb960fde2e";
  var s = document.getElementsByTagName("script")[0];
  s.parentNode.insertBefore(hm, s);
})();
</script>
<title>X-WRT/OpenWrt/LEDE 固件下载</title></head>
<body><h1>固件下载列表</h1>
<hr>  <h2>列表</h2>
  <p>这些是常用的 <b>LEDE/OpenWrt</b> 固件。ptpt52编译，代号：<font face="Arial Black" size="6">X</font><font size="5" face="Arial Black">-</font><font size="4" face="Arial Black">Wrt </font></p>
  <p>固件无线默认名称：X-WRT_XXXX，密码：88888888<br>
固件管理界面：http://192.168.15.1/<br>
管理界面账户/密码：root/admin<br>
  </p>
  <p><a href="sch_index.html">校园网固件</a> &nbsp;
     <a href="sdk/">SDK Downloads</a> &nbsp;
     源代码: <a href="https://github.com/x-wrt">https://github.com/x-wrt</a> &nbsp;
     官网: <a href="https://x-wrt.com">https://x-wrt.com</a>
  </p>
EOF

echo '<table><tr><th>Image for your Device</th><th>File Size</th><th>Date(GMT+8)</th></tr>' >>$OUT
idx=0
cat map.list | while read line; do
	idx=$((idx+1))
	name=`echo $line | cut -d: -f1`
	files=`echo $line | cut -d: -f2`
	filen=`echo $files | wc -w`
	files=`for _file in $files; do echo $_file; done | sort -n`
	#TRS='style="background: rgba(255, 255, 255, 0.8);"'
	TRS='class="tr'$((idx%2))'"'
	#test $((idx%2)) -eq 1 && TRS=""
	echo '<tr '$TRS'><td colspan=3>'$name'</td></td>' >>$OUT
	for file in $files; do
		TZ=:/usr/share/zoneinfo/Asia/Shanghai LC_ALL=C ls -lh --time-style="+%Y-%m-%d %H:%M:%S" $file | awk '{print $5" "$6" "$7}' | while read size _date; do
			image='<a href="'$file'">'$file'</a>'
			echo '<tr '$TRS'><td>'$image'</td><td>'$size'</td><td>'$_date'</td></tr>' >>$OUT
		done
		td=""
	done
done

echo '</table></body></html>' >>$OUT
