# parameter

| 名称   | 说明             | 默认值 |
| ------ | ---------------- | ------ |
| DWIDTH | 输入数据位宽     | 8      |
| AWIDTH | 数据窗口地址宽度 | 6      |
 
# port

| 名称       | 类型   | 位宽   | 说明                 |
| ---------- | ------ | ------ | -------------------- |
| clk        | input  | 1      | 系统时钟             |
| rst_n      | input  | 1      | 系统复位信号，低有效 |
| address    | input  | AWIDTH | 地址数据             |
| write_req  | input  | 1      | 写有效               |
| write_data | input  | DWIDTH | 写数据               |
| read_data  | output | DWIDTH | 读数据               |