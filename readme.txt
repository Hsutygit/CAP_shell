#2022-11-01
1) sh rename.sh,数据重命名，标记到时，然后在data_rename里完成数据初步筛选；
2) sh remove_IR.sh,去仪器响应，然后再用SAC进一步筛选数据；查看到时是否准确，手动标记不准确的到时（ppk p 3 a m, t1,q,wh）；
3) sh rotate_cut_decimate.sh,旋转到大圆路径，截取部分波形，降采样；
4) sh genWeight.sh,生成权重文件；
5) sh genfk.sh > runfk.sh,准备速度模型文件；
6）sh runfk.sh,生成格林函数；
7) 修改cap3D.pl 中格林函数与cap_plt.pl路径，
require "/mnt/e/EQs/2016Menyuan/cap/M3.9/cap_plt.pl";

#================defaults======================================
$cmd = "cap3D";
#$green = "$home/data/models/Glib";	#green's function location
$green = "/mnt/e/EQs/2016Menyuan/cap/M3.9";


8) sh cap_Menyuan.sh,