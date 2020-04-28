cp index.html index.html.old
echo -n >index.html
cat <<EOF >>index.html
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
  tr {
    background: rgba(255, 255, 255, 0.8);
  }
  tr:hover {
    background: rgba(255, 255, 255, 0.6);
  }
  p, th, td {
    font-size: 14px;
  }
  th, td {
    height: 20px;
    vertical-align: middle;
    white-space: nowrap;
    padding: 0.2em 0.5em;
    border: 1px solid #ccc;
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
<title>X-WRT/OpenWrt/LEDE 固件SDK下载</title></head>
<body><h1>固件SDK下载列表</h1>
<hr>  <h2>列表</h2>
  <p>这些是常用的 <b>LEDE/OpenWrt</b> 固件SDK包。ptpt52编译，代号：<font face="Arial Black" size="6">X</font><font size="5" face="Arial Black">-</font><font size="4" face="Arial Black">Wrt </font></p>
EOF

echo '<table><tr><th>Image SDK for your Device</th><th>File Size</th><th>Date(GMT+8)</th></tr>' >>index.html
cat sdk_map.list | while read name; do
	files=$name
	for _file in $files; do echo $_file; done | sort -n | while read file; do
		TZ=:/usr/share/zoneinfo/Asia/Shanghai LC_ALL=C ls -lh --time-style="+%Y-%m-%d %H:%M:%S" $file | awk '{print $5" "$6" "$7}' | while read size _date; do
			image='<a href="'$file'">'$file'</a>'
			echo '<tr><td>'$image'</td><td>'$size'</td><td>'$_date'</td></tr>' >>index.html
		done
	done
done

echo '</table></body></html>' >>index.html
