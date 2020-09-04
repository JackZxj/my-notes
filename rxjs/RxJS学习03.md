# Learning on RxJS 03

[30 天精通 RxJS](https://blog.jerry-hong.com/series/rxjs/)
感谢大佬带路学习。

## Observable Operators & Marble Diagrams

### Operator

> Operators 就是一個個被附加到 Observable 型別的函式，例如像是 map, filter, contactAll... 等等，所有這些函式都會拿到原本的 observable 並回傳一個新的 observable，就像有點像下面這個樣子

``` JS
var people = Rx.Observable.of('Jerry', 'Anna');

function map(source, callback) {
    return Rx.Observable.create((observer) => {
        return source.subscribe(
            (value) => {
                try {
                    observer.next(callback(value));
                } catch (e) {
                    observer.error(e);
                }
            },
            (err) => {
                observer.error(err);
            },
            () => {
                observer.complete();
            }
        )
    })
}

var helloPeople = map(people, (item) => item + ' Hello~');

helloPeople.subscribe(console.log);
// Jerry Hello~
// Anna Hello~
```

> 這裡有兩個重點是我們一定要知道的，每個 operator 都會回傳一個新的 observable，而我們可以透過 `create` 的方法建立各種 operator。

### Marble diagrams

用于可视化 observable 的方法

``` BASH
# 用 - 來表達一小段時間，這些 - 串起就代表一個 observable
-----------------

# X則代表有錯誤發生
------------X

# | 則代表 observable 結束
----------------|

# 時間序中可能會發送出值(value)，如果值是數字則直接用阿拉伯數字取代，其他的資料型別則用相近的英文符號代表
# eg: var source = Rx.Observable.interval(1000);
-----0-----1-----2-----3--...

# 小括號代表著同步發生
# eg: var source = Rx.Observable.of(1,2,3,4);
(1234)|

# 数值前后转换
# var source = Rx.Observable.interval(1000);
# var newest = source.map(x => x + 1); 
source: -----0-----1-----2-----3--...
            map(x => x + 1)
newest: -----1-----2-----3-----4--...
```

### Operators

#### map

> Observable 的 map 方法使用上跟陣列的 map 是一樣的，我們傳入一個 callback function，這個 callback function 會帶入每次發送出來的元素，然後我們回傳新的元素

#### mapTo

> mapTo 可以把傳進來的值改成一個固定的值，如下

``` JS
var source = Rx.Observable.interval(1000);
var newest = source.mapTo(2);
newest.subscribe(console.log);
// source: -----0-----1-----2-----3--...
//             mapTo(2)
// newest: -----2-----2-----2-----2--...
```

#### filter

> filter 在使用上也跟陣列的相同，我們要傳入一個 callback function，這個 function 會傳入每個被送出的元素，並且回傳一個 boolean 值，如果為 true 的話就會保留，如果為 false 就會被濾掉，如下

``` JS
var source = Rx.Observable.interval(1000);
var newest = source.filter(x => x % 2 === 0);
newest.subscribe(console.log);
// source: -----0-----1-----2-----3-----4-...
//             filter(x => x % 2 === 0)
// newest: -----0-----------2-----------4-...
```

## 简易拖拉实践 - take, first, takeUntil, concatAll

### Operators

**take:** 取前 n 个可观测对象后结束

``` JS
var source = Rx.Observable.interval(1000);
var example = source.take(3);

example.subscribe({
    next: (value) => {
        console.log(value);
    },
    error: (err) => {
        console.log('Error: ' + err);
    },
    complete: () => {
        console.log('complete');
    }
});
// source : -----0-----1-----2-----3--..
//                 take(3)
// example: -----0-----1-----2|
```

**first:** first() 等效 take(1)

**takeUntil:** first() 等效 take(1)

-----------

# To be continue......
