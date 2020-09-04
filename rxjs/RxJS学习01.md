# Learning on RxJS 01

[30 天精通 RxJS](https://blog.jerry-hong.com/series/rxjs/)
感谢大佬带路学习。

## About Reactive

### 非同步常见情况举例

* **Race Condition:** 发生请求更新A后立即请求A时，由于网络原因可能造成的两个请求被后台响应的先后顺序
* **Memory Leak:** 在 SPA(Single Page Application) 中对某子页面 A 注册事件监听，但是在页面切换时没有移除事件监听
* **Complex State:** 前后台交互时涉及到请求权限以及中断等操作
* **Exception Handling:** 非同步操作时的异常处理

### rxjs 示例

``` js
// 当你只想监听一次点击事件

// 原生js
var handler = (e) => {
    console.log(e);
    document.body.removeEventListener('click', handler); // 移除事件监听器
}
document.body.addEventListener('click', handler); // 注册事件监听

// rxjs
Rx.Observable
    .fromEvent(document.body, 'click') // 注册监听
    .take(1) // 只取一次，之后就释放内存
    .subscribe(console.log);
```

### About Reactive Programming

`Reactive Programming` : 当资源发生变动时自己通知所属发生变动

* 发生变动 => 状态非同步，随时可变更
* 自己通知 => 不需要一直手动监听资源

## About Functional Programming

### FP 概念

一切皆函数的概念。

``` js
// 正常写法
a = (5 + 6) - 1 * 3;

// FP写法
const add = (a, b) => a + b
const mul = (a, b) => a * b
const sub = (a, b) => a - b

a = sub(add(5, 6), mul(1, 3));
```

### FP 基本条件

``` js
// 1. 函数可以赋值给变量
var a = function() {};

// 2. 函数可以作为参数传入
fetch('www.baidu.com').then(function(response) {});

// 3. 函数可以作为返回值
var a = function(a) {
    return function(b) {
        return a > b;
    }
} // a(1)(2) === false;
```

### FP 特性

#### Expression, no Statement

FP都是表达式 (Expression， 运算过程，一定有返回值，如 `add(1, 2);` ) 而不是陈述式 (Statement， 表达的是声明，如 `a = 1;` )

`a = add(1, 2);` 这是一个陈述式，陈述的结果需要表达式产生。
`var a; if(a === 3){}` if 语句也是一个陈述式，需要表达式 `a === 3` 返回结果才能执行 `{}` 中的程序。

函数陈述式与函数表达式

``` js
// 函数陈述式
// 可以在声明之前调用函数
greet();

function greet() {
    console.log('hello world');
}

// 函数表达式
// 错误写法
anonymousGreet(); // anonymousGreet is not a function ; anonymousGreet 会先被声明为 undefined！
var anonymousGreet = function() {
    console.log('Function expression could be anonymous.');
}
// 正确写法
var anonymousGreetA = function() {
    console.log('Function expression could be anonymous.');
}
anonymousGreetA(); // 必须等到赋予函数对象后才能调用
```

#### Pure Function

> Pure function 是指 一個 function 給予相同的參數，永遠會回傳相同的返回值，並且沒有任何顯著的副作用(Side Effect)

eg:

``` js
var arr = [1, 2, 3, 4, 5];

// slice 函数是一个 Pure Function
arr.slice(0, 3); // [1, 2, 3]
arr.slice(0, 3); // [1, 2, 3]
arr.slice(0, 3); // [1, 2, 3]

// splice 不是一个 Pure Function
arr.splice(0, 3); // [1, 2, 3]
arr.splice(0, 3); // [4, 5]
arr.slice(0, 3); // []
```

#### Side Effect

> Side Effect 是指一個 function 做了跟本身運算返回值沒有關係的事，比如說修改某個全域變數，或是修改傳入參數的值，甚至是執行 `console.log` 都算是 Side Effect。
>  
> Functional Programming 強調沒有 Side Effect，也就是 function 要保持純粹，只做運算並返回一個值，沒有其他額外的行為。

#### Referential transparency

> 前面提到的 pure function 不管外部環境如何，只要參數相同，函式執行的返回結果必定相同。這種不依賴任何外部狀態，只依賴於傳入的參數的特性也稱為 引用透明(Referential transparency)

#### 利用參數保存狀態

``` js
// 实际上 findIndex 中多保留了一个 start 用来记录当前已经遍历到第几个了
function findIndex(arr, predicate, start = 0) {
    if (0 <= start && start < arr.length) {
        if (predicate(arr[start])) {
            return start;
        }
        return findIndex(arr, predicate, start + 1);
    }
}
findIndex(['a', 'b'], x => x === 'b'); // 找陣列中 'b' 的 index
```

>> 這邊用到了遞回，遞回會不斷的呼叫自己，製造多層 stack frame，會導致運算速度較慢，而這通常需要靠編譯器做優化！
>
>> 那 JS 有沒有做遞回優化呢？ 恭喜大家，ES6 提供了 尾呼優化(tail call optimization)，讓我們有一些手法可以讓遞回更有效率！

注： 遞 = 递

### FP 优势

#### 提升可读性

``` js
[6, 2].concat([5, 4]) // 拼接
    .sort() // 排序
    .filter(x => x > 5) // 选出大于 5 的数
```

#### 提升可维护性

> 因為 Pure function 等特性，執行結果不依賴外部狀態，且不會對外部環境有任何操作，使 Functional Programming 能更好的除錯及撰寫單元測試。

#### 易于平行处理

> Functional Programming 易於做併行/平行(Concurrency/Parallel)處理，因為我們基本上只做運算不碰 I/O，再加上沒有 Side Effect 的特性，所以較不用擔心 deadlock 等問題。

## FP 通用函数

### ForEach

``` js
var arr = ['Jerry', 'Anna'];

// 通常的遍历做法
for (var i = 0; i < arr.length; i++) {
    console.log(arr[i]);
}
// FP 思想
arr.forEach(item => console.log(item));
```

### FP Practice

> 把 newCourseList 每個元素的 { id, title } 塞到新的陣列 idAndTitle

``` js
var newCourseList = [{
            "id": 511021,
            "title": "React for Beginners",
            "coverPng": "https://res.cloudinary.com/dohtkyi84/image/upload/v1481226146/react-cover.png",
            "rating": 5
        },
        {
            "id": 511022,
            "title": "Vue2 for Beginners",
            "coverPng": "https://res.cloudinary.com/dohtkyi84/image/upload/v1481226146/react-cover.png",
            "rating": 5
        },
        {
            "id": 511023,
            "title": "Angular2 for Beginners",
            "coverPng": "https://res.cloudinary.com/dohtkyi84/image/upload/v1481226146/react-cover.png",
            "rating": 5
        },
        {
            "id": 511024,
            "title": "Webpack for Beginners",
            "coverPng": "https://res.cloudinary.com/dohtkyi84/image/upload/v1481226146/react-cover.png",
            "rating": 4
        }
    ],
    idAndTitle = [];

// 传统的遍历
newCourseList.forEach((course) => {
    idAndTitle.push({
        id: course.id,
        title: course.title
    });
});

// 更抽象的做法
// 为每一个 Array 实例创建一个 extract 方法，原博客用的是 map 方法，map 在 ES2015 后已经成为 Array 的一个自带方法，实际上这里的 prototype 是可以随意自定义或者改写原有的函数
Array.prototype.extract = function(callback) {
    // 定义一个变量用于存储返回的结果
    var res = [];
    // 这里的 this 指的是这个 Array 实例
    // array.forEach(element, ?index)
    this.forEach((element, index) => {
        // 这里的 callback 和下面调用时传入的函数传参数量不一样，但 js 是支持这种实际传参比定义的参数更多的写法，实际接收的参数以定义为准（毕竟函数怎么执行是定义出来的）
        res.push(callback(element, index));
    });
    return res;
}
idAndTitle = newCourseList.extract((course) => {
    return {
        id: course.id,
        title: course.title
    }
});
// 利用箭头函数更精简的写法
// newCourseList.extract(course => ({ id: course.id, title: course.title }));
```

> 如果我們希望過濾一個陣列，留下陣列中我們想要的元素，並產生一個新的陣列，要怎麼做呢？先讓我們用 forEach 完成！
> 讓我們過濾出 rating 值是 5 的元素過濾出 rating 值是 5 的元素

``` js
var ratingIsFive = [];

// 传统遍历做法
newCourseList.forEach(course => {
    if (course.rating === 5) {
        ratingIsFive.push(course);
    }
});

// 抽象方法
Array.prototype.filterTarget = function(callback) {
    var res = [];
    this.forEach((item, index) => {
        if (callback(item, index)) {
            res.push(item);
        }
    });
    return res;
}
ratingIsFive = newCourseList.filterTarget(course => course.rating === 5);

// 通过添加 prototype 方法，可以进行组合操作，使得操作的意图更加明了
// eg： 获取 rating 为 5 的所有 course title
var courseTitleInRatingFive = newCourseList
    .filterTarget(course => course.rating === 5)
    .extract(course => course.title);
```

> 有時候我們會遇到組出一個二維陣列，但我們希望陣列是一維的，問題如下：
> 假如我們要取出 courseLists 中所有 rating 為 5 的課程，這時可能就會用到兩個 forEach

``` JS
var user = {
    id: 888,
    name: 'JerryHong',
    courseLists: [{
        "name": "My Courses",
        "courses": [{
            "id": 511019,
            "title": "React for Beginners",
            "coverPng": "https://res.cloudinary.com/dohtkyi84/image/upload/v1481226146/react-cover.png",
            "tags": [{
                id: 1,
                name: "JavaScript"
            }],
            "rating": 5
        }, {
            "id": 511020,
            "title": "Front-End automat workflow",
            "coverPng": "https://res.cloudinary.com/dohtkyi84/image/upload/v1481226146/react-cover.png",
            "tags": [{
                "id": 2,
                "name": "gulp"
            }, {
                "id": 3,
                "name": "webpack"
            }],
            "rating": 4
        }]
    }, {
        "name": "New Release",
        "courses": [{
            "id": 511022,
            "title": "Vue2 for Beginners",
            "coverPng": "https://res.cloudinary.com/dohtkyi84/image/upload/v1481226146/react-cover.png",
            "tags": [{
                id: 1,
                name: "JavaScript"
            }],
            "rating": 5
        }, {
            "id": 511023,
            "title": "Angular2 for Beginners",
            "coverPng": "https://res.cloudinary.com/dohtkyi84/image/upload/v1481226146/react-cover.png",
            "tags": [{
                id: 1,
                name: "JavaScript"
            }],
            "rating": 4
        }]
    }]
};

var allCourseIds = [];

// 传统遍历
user.courseLists.forEach(list => {
    list.courses.forEach(course => {
        if (course.rating === 5) {
            allCourseIds.push(course);
        }
    });
});

// 稍微优化
user.courseLists.forEach(list => {
    list.courses
        .filterTarget(course => course.rating === 5)
        .forEach(course => {
            allCourseIds.push(course)
        });
});

// 多维数组合并为一维
Array.prototype.concatAll = function() {
    var res = [];
    // spread 为 ES6 后支持的特性，用于把数组拆成单独的传输
    this.forEach(array => {
        res.push(...array);
    });

    // 或者可以用两层 forEach
    // this.forEach(array => {
    //     array.forEach(item => {
    //         res.push(item);
    //     });
    // });

    // 或者用 apply
    // this.forEach(array => {
    //     res.push.apply(res, array);
    // });
    return res;
}

allCourseIds = user.courseLists
    .extract(item => (item.courses.filterTarget(course => course.rating === 5)))
    .concatAll()
```

### Test

使用上述的 `concatAll`  `extract`  `filterTarget`  `forEach` 从 `courseLists` 提取 `[{id: id, title: title, cover: covers[0].url}]` （不能使用数组操作）

``` JS
var courseLists = [{
    "name": "My Courses",
    "courses": [{
        "id": 511019,
        "title": "React for Beginners",
        "covers": [{
            width: 150,
            height: 200,
            url: "http://placeimg.com/150/200/tech"
        }, {
            width: 200,
            height: 200,
            url: "http://placeimg.com/200/200/tech"
        }, {
            width: 300,
            height: 200,
            url: "http://placeimg.com/300/200/tech"
        }],
        "tags": [{
            id: 1,
            name: "JavaScript"
        }],
        "rating": 5
    }, {
        "id": 511020,
        "title": "Front-End automat workflow",
        "covers": [{
            width: 150,
            height: 200,
            url: "http://placeimg.com/150/200/arch"
        }, {
            width: 200,
            height: 200,
            url: "http://placeimg.com/200/200/arch"
        }, {
            width: 300,
            height: 200,
            url: "http://placeimg.com/300/200/arch"
        }],
        "tags": [{
            "id": 2,
            "name": "gulp"
        }, {
            "id": 3,
            "name": "webpack"
        }],
        "rating": 5
    }]
}, {
    "name": "New Release",
    "courses": [{
        "id": 511022,
        "title": "Vue2 for Beginners",
        "covers": [{
            width: 150,
            height: 200,
            url: "http://placeimg.com/150/200/nature"
        }, {
            width: 200,
            height: 200,
            url: "http://placeimg.com/200/200/nature"
        }, {
            width: 300,
            height: 200,
            url: "http://placeimg.com/300/200/nature"
        }],
        "tags": [{
            id: 1,
            name: "JavaScript"
        }],
        "rating": 5
    }, {
        "id": 511023,
        "title": "Angular2 for Beginners",
        "covers": [{
            width: 150,
            height: 200,
            url: "http://placeimg.com/150/200/people"
        }, {
            width: 200,
            height: 200,
            url: "http://placeimg.com/200/200/people"
        }, {
            width: 300,
            height: 200,
            url: "http://placeimg.com/300/200/people"
        }],
        "tags": [{
            id: 1,
            name: "JavaScript"
        }],
        "rating": 5
    }]
}];

// my answer
// 失败了，不调用数组去除不了
var res = courseLists
    .extract(item => item.courses)
    .concatAll()
    .extract(course => ({
        id: course.id,
        title: course.title,
        cover: course.covers
            .filterTarget(cover => cover.width === 150)
            .extract(cover => cover.url)[0]
    }));

// 正确答案
var result = courseLists
    .extract(item => item.courses
        .extract(course => course.covers
            .filterTarget(cover => cover.width === 150) // 提取的是 [{width: 150,height: 200,url: "http://placeimg.com/300/200/xxx"}]
            .extract(cover => ({ // 这一步是最不容易想到的操作，提取出 url，和循环中的id、title组合
                id: course.id,
                title: course.title,
                cover: cover.url
            }))
        ).concatAll()) // 一个 courses 有两个 [{width: 150,height: 200,url: "http://placeimg.com/300/200/xxx"}] 需要先进行一次组合
    .concatAll()
```
