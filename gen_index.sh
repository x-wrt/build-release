OUT=index.html
cp $OUT $OUT.old
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
<title>X-WRT/OpenWrt/LEDE 固件下载</title></head>
<body><h1>固件下载列表</h1>
<hr>  <h2>列表</h2>
  <p>这些是常用的 <b>LEDE/OpenWrt</b> 固件。ptpt52编译，代号：
			<svg width="103.868" height="29.117" viewBox="0 0 103.868 29.117" xmlns="http://www.w3.org/2000/svg"><g id="svgGroup" stroke-linecap="round" fill-rule="evenodd" font-size="9pt" stroke="#000" stroke-width="0.00mm" fill="none">
			<path d="m103,0l-63,0c-2.244,0.252 -3.478,1.624 -3.696,4.128l0,20.847c0.215,2.501 1.447,3.868 3.676,4.129l60,0c2.23,-0.261 3.461,-1.629 3.677,-4.129l0,-20.847c-0.217,-2.504 -1.452,-3.876 -3.694,-4.128" fill="#f7971d"/>
			<path d="m70.945,3.604l0,-3.604l20.162,0l0,3.604l-8.279,0l0,21.603l-3.603,0l0,-21.603l-8.28,0zm-3.955,6.345l0,11.795q0,0.721 -0.272,1.354a3.485,3.485 0 0 1 -0.739,1.098a3.513,3.513 0 0 1 -1.089,0.739a3.313,3.313 0 0 1 -1.3,0.272a3.79,3.79 0 0 1 -0.045,0l-9.299,0a3.343,3.343 0 0 1 -1.336,-0.272a3.485,3.485 0 0 1 -1.098,-0.739q-0.466,-0.466 -0.739,-1.098q-0.272,-0.633 -0.272,-1.354l0,-11.795q0,-0.72 0.272,-1.353a3.485,3.485 0 0 1 0.739,-1.099q0.465,-0.466 1.098,-0.738a3.343,3.343 0 0 1 1.336,-0.273l9.299,0a3.355,3.355 0 0 1 1.187,0.209a3.201,3.201 0 0 1 0.158,0.064q0.624,0.272 1.089,0.738q0.466,0.466 0.739,1.099q0.272,0.633 0.272,1.353zm-25.91,-9.949l3.604,0l0,25.207l-3.604,0l0,-25.207zm22.465,9.949l-9.299,0l0,11.795l9.299,0l0,-11.795z" fill="#fe9e24"/>
			<path d="m0.193,2.05l4.342,0l6.733,9.439l6.767,-9.439l4.36,0l-8.93,12.498l9.123,12.709l-4.359,0l-6.961,-9.686l-6.909,9.686l-4.359,0l9.123,-12.709l-8.93,-12.498zm26.35,16.787l0,-3.463l8.42,0l0,3.463l-8.42,0z" fill="white" stroke-width="0.00mm" stroke="#000"/>
			<path d="m48.217,27.257l-3.604,0l-6.047,-18.721l3.498,0l4.43,14.116l4.131,-14.116l3.533,0l4.131,14.116l4.43,-14.116l3.498,0l-6.047,18.721l-3.604,0l-4.183,-13.746l-4.166,13.746zm38.865,-15.258l0,-3.463l4.57,0l0,-5.765l3.463,0l0,5.765l6.153,0l0,3.463l-6.153,0l0,11.795l6.153,0l0,3.463l-6.153,0a3.343,3.343 0 0 1 -1.336,-0.272a3.593,3.593 0 0 1 -1.107,-0.739a3.413,3.413 0 0 1 -0.747,-1.098q-0.273,-0.633 -0.273,-1.354l0,-11.795l-4.57,0zm-6.68,0l-7.136,0l0,15.258l-3.446,0l0,-18.721l3.446,0l0,3.305q0.035,-0.686 0.316,-1.292q0.281,-0.606 0.747,-1.055a3.444,3.444 0 0 1 1.081,-0.703q0.615,-0.255 1.319,-0.255l3.673,0a3.355,3.355 0 0 1 1.188,0.209a3.201,3.201 0 0 1 0.157,0.064q0.624,0.272 1.099,0.738a3.413,3.413 0 0 1 0.747,1.099q0.272,0.633 0.272,1.353l0,3.164l-3.463,0l0,-3.164z" fill="black" stroke-width="0.05mm" stroke="#000"/>
			</g></svg>
  </p>
  <p>固件无线默认名称：X-WRT_XXXX，密码：88888888<br>
固件管理界面：http://192.168.15.1/<br>
管理界面账户/密码：admin/admin<br>
SSH登录账户/密码：root/admin  需要<a href="https://blog.x-wrt.com/docs/ssh-open/">进入界面-系统-管理权页面-开启SSH登录</a><br>
  </p>
  <p><a href="sch_index.html">校园网固件</a> &nbsp;
     <a href="sdk/">SDK Downloads</a> &nbsp;
     源代码: <a href="https://github.com/x-wrt">https://github.com/x-wrt</a> &nbsp;
     官网: <a href="https://x-wrt.com">https://x-wrt.com</a>
  </p>
  <p><a href="ar71xx">ar71xx系列</a> &nbsp;
  </p>
  <p><a href="https://github.com/x-wrt/build-release/releases">历史版本下载(Download on Github)</a> &nbsp;
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
		TZ=:/usr/share/zoneinfo/Asia/Shanghai LC_ALL=C ls -lh --full-time $file | awk '{print $5" "$6" "$7}' | while read size _date; do
			image='<a href="'$file'">'$file'</a>'
			echo '<tr '$TRS'><td>'$image'</td><td>'$size'</td><td>'$_date'</td></tr>' >>$OUT
		done
		td=""
	done
done

echo '</table></body></html>' >>$OUT
