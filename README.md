**อธิบายโค้ดที่ป้องกันการ lock เงินไว้ใน contract**

มีคำสั่ง abort เพื่อทำการยกเลิกเกม โดยถ้ายังมีผู้เล่นแค่คนเดียว (มีแค่ player 0) จะทำการยกเลิกเกม โดยการคืนเงินให้ผู้เล่น จากนั้น reset เกม

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXcNeGwmUteCvuA9zM1TyGudGoI8JPaK_EPW1x7QImRMCDZdiNg1tp5UQSiC7-lNnUAC17rwTzZC476ePyv22Oo9L4JtCP6BOYjsm4YUE_MudwcY1SSqAoY_OU2GHX-Ur9ptYfV4ug?key=NCY2C7HOnfnbE9iy7ruLCBOl)

**อธิบายโค้ดส่วนที่ทำการซ่อน choice และ commit**

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXeIOmzeu8MnL9imbNtdBJuAo0UOcPiIs5-DjiDjuzo2dHfcqrVTOyc7csb5027nBtkcss8iHKiT6taGnhau1_FsElt9kfkW45WUANunRM1R8jbLRSft1slNQLjZayItVDCT7sb0?key=NCY2C7HOnfnbE9iy7ruLCBOl)

นำ choice ที่เราจะเลือก (0-4) มาทำการ pad ให้กลายเป็น 32 byte ก่อน

จากนั้นนำมา hash แล้วใช้คำสั่ง commit เพื่อ commit ค่า hash ไว้ใน block

ทำให้ไม่สามารถทำการ front running ได้ เพราะที่เรา commit  ไปเป็นค่า hash ไม่ใช่ค่า choice โดยตรง

เพราะ hash เป็น one way function

**อธิบายโค้ดส่วนที่จัดการกับความล่าช้าที่ผู้เล่นไม่ครบทั้งสองคนเสียที**![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXfxTpLw2-WmTP4CUzMRBATI3Ndr-0zEmyp2Vce1BDKzSjz4NOsoZlcvVOmdCFVniFHtPWUAAnHr2qzGvjvRL1E35ZRRfk3udsvnVZbC_eUHlRrDaEHb9ghiRZDJxFx0OhY_B57uRA?key=NCY2C7HOnfnbE9iy7ruLCBOl)****

มีการตั้ง deadline ด้วย library TimeUnit ที่อาจารย์ได้ให้มา

โดยในตอน commit และ reveal จะตั้ง deadline เป็น block.timestamp + 300 (5 นาที) 

โดยจะใช้คำสั่ง abort ในการจัดการความล้าช้า โดยการยกเลิกเกม

1.ถ้าเราเข้าเกมมา แล้วยังไม่มีอีกคนเข้าเกมมาสักที เราสามารถกด abort เกมทิ้งได้เลย แล้วเราจะได้เงินคืน

2.ถ้าอยูใน state Commit แล้ว ที่ทั้ง 2 คนจะต้อง commit แล้วเรากด commit แล้ว อีกคนไม่ยอมกด commit สักที เราสามารถกด withdraw และเอาเงินไป 3 ใน 5 ได้ (1.2 ether) เพราะเขาอาจจะแค่ลืมมากด commit แต่เพื่อป้องกันคนมาป่วนเลยจะคืนให้แค่ 2 ใน 3 (0.8 ether) ถือเป็นค่าเสียเวลาของคนที่จะเล่น

3.ถ้าอยู่ใน state Reveal แล้วอีกคนมันไม่ยอม commit สักที => คุณก็รับเต็มเลย อีกคนปรับแพ้ เพราะถือว่าหวังจะทำ front running เราปรับแพ้เลย 

โดยทั้ง commit และ reveal จะกด abort ได้ ตัวเองต้องกด commit หรือ reveal ใน state นั้น ๆ ก่อน เพราะเราเข้าเกมมาแล้ว แปลว่ายินยอมที่จะเล่นเกมแล้ว จะไม่ยอมให้ยกเลิกครับ

**อธิบายโค้ดส่วนทำการ reveal และนำ choice มาตัดสินผู้ชนะ** 

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXd1L9O1_2y7Pl5ttPhbaZmt2c3X2uWtUaSURAc4PbWjoMOhojhKNaJSKph6n9qt8Q752cH_dI9h5NyRtfQ_Rrr8zG_BFdAySmkMU_xwUTZ2isTRVJwrTNTbuHdI_HGlaT_uy_tfiw?key=NCY2C7HOnfnbE9iy7ruLCBOl)

เรียกใช้ reveal จาก library commitReveal โดยตัว library จะตรวจสอบว่าค่า paddedData ที่ใส่เข้าไป มันมีค่า hash ที่ได้ ตรงกับที่ commit ไปหรือไม่ ถ้าตรงมันจะทำการ trigger event ออกมาเพื่อแจ้งเตือน

จากนั้นจะทำการเก็บ choice ที่ได้เอาไว้ เพื่อตรวจสอบค่า แต่ค่า choice ตรงนี้ที่เก็บไว้อาจถูก front running ได้ ดังนั้น ถ้าอีกคนไม่ยอม reveal จะถูกปรับแพ้ทันที

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXc3_vvPMZJZbdr6DA78qwzCiBjINzQSdwNZg-eSLoq8XYfRUZ8KXtdD5TlMX4Cgow-4_0buauXqRR6g_eLv5ZXeeqslJwlJ84W4YEl6tgDMLcG8i4EcZfRYPNW_GpNiWBY-h28gcg?key=NCY2C7HOnfnbE9iy7ruLCBOl)

โดย logic ของการคิดคนชนะ แพ้ ของ RPSLS จะเป็นดังนี้

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXdpApX0fcs-slfgTz_OzZBkeFIhtHIvxQpT-J6ajwhRwOkXi69EUnxf_dOMnIeNpoytVtLUNhzS5AGzs49CfgQpgeb3NqNI8L56ZO6QHpyxBIgEfurVN2zIJ9JYNoW9IqntEAA3DQ?key=NCY2C7HOnfnbE9iy7ruLCBOl)

โดยจากเดิมที่คิดแค่ตัวเองชนะตัว +1 ตอนนี้จะคิดว่าตัวเองชนะตัว +1 และ +3 และเพิ่มเป็น %5 เพราะมี 5 choice
