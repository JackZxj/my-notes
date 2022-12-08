# word 不常用但很有用的快捷操作

## 批量删除超链接

快速删除所有超链接，首先按 `Ctrl+A` 选中全文，之后 `Ctrl+Shift+F9` 即可去掉所有的超链接

## 查找超链接

1. `Ctrl+H` 打开 `查找和替换` 选择 `定位(G)`
2. `定位目标` 选择 `域` -> `请输入域名` 选择 `HYPERLINK`
3. 然后就能一处一处查找超链接

## 含换行符的查找

`Ctrl+H` 打开 `查找和替换`, 使用 `^p` 替代换行符进行查找

段落匹配：

* ^13：表示段落标记 
* {2,}：表示出现2次以上 
* ^13{2,}：表示出现两次以及以上的段落比较 （需要在更多中勾选通配符）

## markdown 转 word

可以参考 http://t.zoukankan.com/kofyou-p-14932700.html

## 一些有用的宏

**启用宏：**

`文件` -> `选项` -> `自定义功能区` -> `主选项卡` -> `勾选开发工具` -> 右下角 `确定` -> 选项卡中多了一个 `开发工具`，点击 -> 选择 `Visual Basic` 弹出界面可以编辑 vb 宏

**运行宏：**

选项卡点击 `开发工具` -> 选择 `宏` -> 在弹窗中可以选择宏运行

```VB
Sub 手写字体()
'
' 手写字体 宏
'
'
Dim R_Character As Range
    Dim FontSize(5)
    ' 字体大小在5个值之间进行波动，可以改写
    ' 12 号为小四
    FontSize(1) = "12"
    FontSize(2) = "12.5"
    FontSize(3) = "13"
    FontSize(4) = "13.5"
    FontSize(5) = "14"

    Dim FontName(2)
    '字体名称在三种字体之间进行波动，可改写，但需要保证系统拥有下列字体
    FontName(1) = "游狼近草体（简）"
    FontName(2) = "蔡云汉硬笔行书简书法字体"
    FontName(2) = "liguofu"
    

    Dim ParagraphSpace(5)
    '行间距 在一定以下值中均等分布，可改写
    ParagraphSpace(1) = "10"
    ParagraphSpace(2) = "9"
    ParagraphSpace(3) = "12"
    ParagraphSpace(4) = "8"
    ParagraphSpace(5) = "11"

    '不懂原理的话，不建议修改下列代码

    For Each R_Character In ActiveDocument.Characters

        VBA.Randomize

        R_Character.Font.Name = FontName(Int(VBA.Rnd * 2) + 1)

        If R_Character.Font.Name = FontName(1) Then
            R_Character.Font.Bold = True      ' 加粗
        Else
            R_Character.Font.Bold = False      ' 加粗
        End If

        R_Character.Font.Size = FontSize(Int(VBA.Rnd * 5) + 1)

        R_Character.Font.Position = Int(VBA.Rnd * 3) + 1

        R_Character.Font.Spacing = Round((VBA.Rnd - 1), 2) ' 随机间距 -1~0 取两位小数

    Next

    Application.ScreenUpdating = True

    For Each Cur_Paragraph In ActiveDocument.Paragraphs

        Cur_Paragraph.LineSpacing = ParagraphSpace(Int(VBA.Rnd * 5) + 1)

    Next
        Application.ScreenUpdating = True
End Sub

Sub a手写体()
'
' a手写体 宏
'
'
Dim R_Character As Range
    Dim FontSize(5)
    ' 字体大小在5个值之间进行波动，可以改写
    ' 12 号为小四
    FontSize(0) = "17.3"
    FontSize(1) = "16.7"
    FontSize(2) = "17"
    FontSize(3) = "16.3"
    FontSize(4) = "17.7"

    Dim FontName(9)
    '字体名称在下面几种字体之间进行波动，可改写，但需要保证系统拥有下列字体
    FontName(0) = "我字酷郭金芳硬笔行书简体"
    FontName(1) = "游狼近草体（简）"
    FontName(2) = "钟齐陈伟勋硬笔行楷简"
    FontName(3) = "蔡云汉硬笔行书简书法字体"
    FontName(4) = "liguofu"
    FontName(5) = "汉仪平安行简"
    FontName(6) = "钟齐立强行书简"
    FontName(7) = "书体坊赵九江钢笔行书"
    FontName(8) = "书体坊硬笔行书3500"

    Dim FontIsBold(9)
    '字体名称在三种字体之间进行波动，可改写，但需要保证系统拥有下列字体
    FontIsBold(0) = True  ' "我字酷郭金芳硬笔行书简体"
    FontIsBold(1) = True  ' "游狼近草体（简）"
    FontIsBold(2) = True  ' "钟齐陈伟勋硬笔行楷简"
    FontIsBold(3) = True  ' "蔡云汉硬笔行书简书法字体"
    FontIsBold(4) = False ' "liguofu"
    FontIsBold(5) = True  ' "汉仪平安行简"
    FontIsBold(6) = True  ' "钟齐立强行书简"
    FontIsBold(7) = False ' "书体坊赵九江钢笔行书"
    FontIsBold(8) = False ' "书体坊硬笔行书3500"

    Dim ParagraphSpace(5)
    '行间距 在一定以下值中均等分布，可改写
    ParagraphSpace(1) = "0.9"
    ParagraphSpace(2) = "1.5"
    ParagraphSpace(3) = "0.7"
    ParagraphSpace(4) = "1.1"
    ParagraphSpace(0) = "1.3"

    '不懂原理的话，不建议修改下列代码
    Randomize
    For Each R_Character In ActiveDocument.Characters
        Dim index As Integer, max As Integer
        If (R_Character.Text = "，") Or (R_Character.Text = "。") Or (R_Character.Text = "“") Or (R_Character.Text = "”") Then
            max = 5
        Else
            max = 9
        End If
        index = Int(Rnd * max) ' 0-max 的随机数
        R_Character.Font.Name = FontName(index)
        R_Character.Font.Bold = FontIsBold(index)

        R_Character.Font.Size = FontSize(Int(Rnd * 5))
        R_Character.Font.Position = Int(Rnd * 3)
        R_Character.Font.Spacing = Round((Rnd - 1.5), 2) ' 随机间距 -1~0 取两位小数
    Next
    Application.ScreenUpdating = True

    For Each Cur_Paragraph In ActiveDocument.Paragraphs
        Cur_Paragraph.LineSpacing = ParagraphSpace(Int(Rnd * 5))
    Next
        Application.ScreenUpdating = True
End Sub


Sub 窗口测试()
'
' 窗口测试 宏
'
'
    Randomize
    Dim index As Integer
    index = Int(Rnd * 8) ' 0-7 的随机数
    MsgBox index & "ss"  ' 拼接字符
End Sub


Sub 批量修改表格()
'
' 批量修改表格，运行后会全选文档内的所有表格，
' 全选之后就能统一修改样式或者更改属性
'
'
    Dim tempTable As Table
    
    Application.ScreenUpdating = False
    
    If ActiveDocument.ProtectionType = wdAllowOnlyFormFields Then
        MsgBox "文档已保护，此时不能选中多个表格!"
        Exit Sub
    End If
    
    ActiveDocument.DeleteAllEditableRanges wdEditorEveryone
    
    For Each tempTable In ActiveDocument.Tables
        tempTable.Range.Editors.Add wdEditorEveryone
    Next
        ActiveDocument.SelectAllEditableRanges wdEditorEveryone
        ActiveDocument.DeleteAllEditableRanges wdEditorEveryone
        Application.ScreenUpdating = True
End Sub
```
