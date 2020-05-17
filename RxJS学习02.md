# Learning on RxJS 02

[30 天精通 RxJS](https://blog.jerry-hong.com/series/rxjs/)
感谢大佬带路学习。

## About Observable

> 要理解 Observable 之前，我們必須先談談兩個設計模式(Design Pattern)， Iterator Pattern 跟 Observer Pattern。

### Observer Pattern

``` JS
// 简单的实例
function clickhandler(event) {
    console.log('you click it!');
}
document.body.addEventListener('click', clickhandler);
```

所以 Observer 就是对某一事件进行监听，并且在事件发生时自动执行监听者的程序。

``` JS
// 原文中还有 es5 的写法，这边就只写 es6 的写法
// PS 实际上我没正经学过 ES。。。写过一阵子TS，但是TS是一个有类型的超集。。。
class Producer {
    constructor() {
        this.listeners = [];
    }

    addListener(listener) {
        if (typeof(listener) === 'function') {
            if (-1 === this.listeners.indexOf(listener)) {
                this.listeners.push(listener);
            } else {
                console.log('Already added!');
            }
        } else {
            console.log('Not a function!');
        }
    }

    removeListener(listener) {
        if (typeof(listener) === 'function') {
            const index = this.listeners.indexOf(listener);
            if (-1 < index) {
                this.listeners.splice(index, 1);
            } else {
                console.log('Not found!');
            }
        } else {
            console.log('Not a function!');
        }
    }

    notify(message) {
        this.listeners.forEach(listener => {
            listener(message);
        });
    }
}

var test = new Producer();

function listener1(message) {
    console.log(message + ' to listener1');
}

var listener2 = (message) => {
    console.log(message + ' to listener2');
}

test.addListener(listener1);
test.addListener(listener2);

test.notify('hello');
```

### Iterator Pattern

迭代器就是用来遍历的，类似指针，它能返回当前指向的元素以及是否结束遍历。

``` JS
// 原生 js 的 iterator
// JavaScript 到了 ES6 才有原生的 Iterator
var arr = [1, 2, 3];
var iterator = arr[Symbol.iterator]();
iterator.next(); // { value: 1, done: false }
iterator.next(); // { value: 2, done: false }
iterator.next(); // { value: 3, done: false }
iterator.next(); // { value: undefined, done: true }
```

> JavaScript 的 Iterator 只有一個 next 方法，這個 next 方法只會回傳這兩種結果：
> 1. 在最後一個元素前： { done: false, value: elem }
> 2. 在最後一個元素之後： { done: true, value: undefined }

``` JS
// ES6 手动实现一个迭代器
class IteratorFromArray {
    constructor(arr) {
        this._arr = arr;
        this._index = 0;
    }

    next() {
        return this._index < this._arr.length ? {
            done: false,
            value: this._arr[this._index++]
        } : {
            done: true,
            value: undefined
        };
    }
}
```

> erator Pattern 雖然很單純，但同時帶來了兩個優勢，第一它漸進式取得資料的特性可以拿來做延遲運算(Lazy evaluation)，讓我們能用它來處理大資料結構。第二因為 iterator 本身是序列，所以可以實作所有陣列的運算方法像 map, filter... 等！

``` JS
// 添加 map 操作
// 目标：调用 map 后返回一个迭代器，用于遍历执行传入 map 的函数
class IteratorFromArray {
    constructor(arr) {
        this._arr = arr;
        this._index = 0;
    }

    next() {
        return this._index < this._arr.length ? {
            done: false,
            value: this._arr[this._index++]
        } : {
            done: true,
            value: undefined
        };
    }

    map(callback) {
        const iterator = new IteratorFromArray(this._arr);
        // 这里的实际返回了一个对象，键为 next，值为匿名函数
        return {
            next: () => {
                const {
                    done,
                    value
                } = iterator.next();
                return {
                    done: done,
                    value: value ? callback(value) : undefined
                };
            }
        }
    }
}

// For test
var a = new IteratorFromArray([1, 2, 3]); // IteratorFromArray {_arr: Array(3), _index: 0}
var ai = a.map(value => value * value); // {next: ƒ}
ai.next(); // {done: false, value: 1}
ai.next(); // {done: false, value: 4}
ai.next(); // {done: false, value: 9}
ai.next(); // {done: true, value: undefined}
```

### Lazy evaluation

> 延遲運算，或說 call-by-need，是一種運算策略(evaluation strategy)，簡單來說我們延遲一個表達式的運算時機直到真正需要它的值在做運算。

``` JS
function* getNumber(words) {
    for (let word of words) {
        if (/^[0-9]+$/.test(word)) {
            yield parseInt(word, 10); // 函数执行到这里时停止，等函数外调用 next() 时才执行 yield 关键字后面的表达式并将返回值赋值给 value
        }
    }
}

const iterator = getNumber('30 天精通 RxJS (04)');
iteratorrr.next(); // {value: 3, done: false}
iteratorrr.next(); // {value: 0, done: false}
iteratorrr.next(); // {value: 0, done: false}
iteratorrr.next(); // {value: 4, done: false}
iteratorrr.next(); // {value: undefined, done: true}
```

> ES6中定义了一种新的函数. 用function*定义生成器函数, 这种函数会返回一个generator对象. 生成器函数在执行时可以暂停，然后又可以在暂停处接着执行。
>  
> [《function* 生成器函数》](https://www.jianshu.com/p/fa3284acd2de)
>  
> ---
>  
> - yield是ES6的新关键字，使生成器函数执行暂停，yield关键字后面的表达式的值返回给生成器的调用者。它可以被认为是一个基于生成器的版本的return关键字。
> - yield关键字实际返回一个IteratorResult（迭代器）对象，它有两个属性，value和done，分别代表返回值和是否完成。
> - yield无法单独工作，需要配合generator(生成器)的其他函数，如next，懒汉式操作，展现强大的主动控制特性。
>
> [《深入理解js中的yield》](https://www.jianshu.com/p/36c74e4ca9eb)

### Summary -> Observable 

> Observer 跟 Iterator 有個共通的特性，就是他們都是 漸進式(progressive) 的取得資料，差別只在於 Observer 是生產者(Producer)推送資料(push)，而 Iterator 是消費者(Consumer)要求資料(pull)!

![push & pull](https://github.com/JackZxj/my-notes/blob/master/images/RxJS/02/push_pull.png)

[图源：原博](https://blog.jerry-hong.com/series/rxjs/thirty-days-RxJS-04/)

> Observable 其實就是這兩個 Pattern 思想的結合，Observable 具備生產者推送資料的特性，同時能像序列，擁有序列處理資料的方法(map, filter...)！
> 更簡單的來說，Observable 就像是一個序列，裡面的元素會隨著時間推送。
>> 注意這裡講的是 思想的結合，Observable 跟 Observer 在實作上還是有差異，這我們在下一篇文章中講到。

## 建立 Observable (一)

RxJS 本质： 一个核心 ( `Observable` ) 三个重点( `Observer` , `Subject` , `Schedulers` )

### 使用 create 创建 Observable

> 建立 Observable 的方法有非常多種，其中 create 是最基本的方法。create 方法在 Rx. Observable 物件中，要傳入一個 callback function ，這個 callback function 會接收一個 observer 參數，這個 callback function 會定義 observable 將會如何發送值。
>> 雖然 Observable 可以被 `create` ，但實務上我們通常都使用 creation operator 像是 from, of, fromEvent, fromPromise 等。這裡只是為了從基本的開始講解所以才用 `create` 

在 [RxJS 中文网](https://cn.rx.js.org/) 中，打开开发者工具 ( `F12` ) 可以试用 RxJS

``` JS
// observable 被订阅时就会依次送出 'Jerry', 'Anna'
var observable = Rx.Observable
    .create(function(observer) {
        observer.next('Jerry'); // RxJS 4.x 以前的版本 onNext
        observer.next('Anna');
    })

console.log('start');
// 订阅这个 observable
observable.subscribe(function(value) {
    console.log(value);
})
console.log('end');
// 依次输出 start Jerry Anna end
```

> 這裡有一個重點，很多人認為 RxJS 是在做非同步處理，所以所有行為都是非同步的。但其實這個觀念是錯的，RxJS 確實主要在處理非同步行為沒錯，但也同時能處理同步行為，像是上面的程式碼就是同步執行的。

``` JS
// 也支持异步处理
var observable = Rx.Observable
    .create(function(observer) {
        observer.next('Jerry'); // RxJS 4.x 以前的版本用 onNext
        observer.next('Anna');
        setTimeout(() => {
            observer.next('RxJS 30 Days!');
        }, 30);
    })

console.log('start');
observable.subscribe(function(value) {
    console.log(value);
});
console.log('end');
// 依次输出
// start                                      VM94:10
// Jerry                                      VM94:12
// Anna                                       VM94:12
// end                                        VM94:14
// RxJS 30 Days!                              VM94:12
```

### Observer

> Observable 可以被訂閱(subscribe)，或說可以被觀察，而訂閱 Observable 的物件又稱為 **觀察者(Observer)**

Observer 的三个方法

* next: Observable 发出新值就会调用一次 next
* error: Observable 发生错误时会被调用，调用后其后续操作将无法执行
* complete: Observable 没有其他资料可以获取时会调用 complete，调用后其后续操作将无法执行

``` JS
var observable = Rx.Observable
    .create(function(observer) {
        try {
            observer.next('Jerry1');
            observer.next('Anna1');
            throw 'error test'; // 这行不注释的话只会运行前两个 next，然后抛出错误给 error
            observer.next('Jack');
        } catch (error) {
            observer.error(error);
        }
        observer.next('Jerry');
        observer.next('Anna');
        observer.error('error after next'); // 不通过 try/catch 的形式也可以直接手动 error，同样只执行前面的语句
        observer.complete(); // 前面没有被结束的话，执行完 complete 就结束订阅了
        observer.next('not work');
        observer.error('error is not work');
    });

// 宣告一個觀察者，具備 next, error, complete 三個方法
// 觀察者可以是不完整的，他可以只具有一個 next 方法
var observer = {
    next: function(value) {
        console.log(value);
    },
    error: function(error) {
        console.error('Error: ' + error);
    },
    complete: function() {
        console.log('complete');
    }
};

// 用我們定義好的觀察者，來訂閱這個 observable	
observable.subscribe(observer);

// 我們也可以直接把 next, error, complete 三個 function 依序傳入 observable.subscribe
observable.subscribe(
    value => {
        console.log(value);
    },
    error => {
        console.log('Error: ', error);
    },
    () => {
        console.log('complete');
    }
);
```

> 有時候 Observable 會是一個無限的序列，例如 click 事件，這時 complete 方法就有可能永遠不會被呼叫！

### Observable vs addEventListener

addEventListener 是事件发生了，将事件产生的结果告知给监听者，对事件结果的处理由监听者决定
Observable 是传入事件的处理方法 (next, error, complete)，当事件序列发生时由 Observable 决定要使用哪个方法处理

``` JS
var observable = Rx.Observable
    .create(function(observer) {
        observer.next('Jerry');
        observer.next('Anna');
    });

observable.subscribe({
    next: function(value) {
        console.log(value);
    },
    error: function(error) {
        console.log(error);
    },
    complete: function() {
        console.log('complete');
    }
});

// 上面的 Observable 实际上相当于下面的函数

function subscribe(observer) {
    observer.next('Jerry');
    observer.next('Anna');
}

subscribe({
    next: function(value) {
        console.log(value);
    },
    error: function(error) {
        console.log(error);
    },
    complete: function() {
        console.log('complete');
    }
});
```

## 建立 Observable (二)

### Creation Operator

创建 Observable 的常用方法

* create
* of
* from
* fromEvent
* fromPromise
* never
* empty
* throw
* interval
* timer

#### of

使用 of 可以直接传入一个序列，可以依次执行

``` JS
var source = Rx.Observable.of('Jerry', 'Anna');

source.subscribe({
    next: function(value) {
        console.log(value);
    },
    complete: function() {
        console.log('complete!');
    },
    error: function(error) {
        console.log(error);
    }
});
// 输出结果
// Jerry
// Anna
// complete!
```

#### from

上述说到 `of` 实际上就是按顺序将参数传入，这不就等价于传入一个序列。那么能不能直接传入序列呢？请使用 `from` ，它可以接收任何可以列举的参数。

``` JS
var arr = ['Jerry', 'Anna', 2016, 2017, '30 days']
var source = Rx.Observable.from(arr);

source.subscribe(
    value => {
        console.log(value);
    },
    error => {
        console.log(error);
    },
    () => {
        console.log('complete!');
    }
);
// 输出结果
// Jerry
// Anna
// 2016
// 2017
// 30 days
// complete!
```

> 記得任何可列舉的參數都可以用喔，也就是說像 Set, WeakSet, Iterator 等都可以當作參數！
> 另外 from 還能接收字串(string)，如下

``` JS
Rx.Observable.from('鐵人賽').subscribe(
    value => {
        console.log(value);
    },
    () => {
        console.log('error');
    }
);
// 鐵
// 人
// 賽
```

> 傳入 Promise 物件，如下

``` JS
Rx.Observable
    .from(new Promise((resolve, reject) => { // resolve 传入的是 next、complete，reject 传入的是 error
        setTimeout(() => {
            resolve('Hello RxJS!');
        }, 1000)
    }))
    .subscribe(
        value => {
            console.log(value);
        }
    );
// 等待 1 秒后输出
// Hello RxJS!
```

> 如果我們傳入 Promise 物件實例，當正常回傳時，就會被送到 next，並立即送出完成通知，如果有錯誤則會送到 error。
>> 這裡也可以用 fromPromise ，會有相同的結果。

PS: 当然上面不会抛出错误，所以我懒得写 error 和 complete 了

##### 关于 Promise

[参考：廖雪峰的 Promise 教程](https://www.liaoxuefeng.com/wiki/1022910821149312/1023024413276544)

由于 JavaScript 是单线程运行，但是实际使用中不可避免地需要进行异步操作，因此在异步操作发生时需要保证异步地行为被正确执行，于是在 ES6 中引入了 Promise。 

``` JS
function test(resolve, reject) {
    var timeOut = Math.random() * 2;
    console.log('set timeout to: ' + timeOut + ' seconds.');
    setTimeout(function() {
        if (timeOut < 1) {
            console.log('call resolve()...');
            resolve('200 OK');
        } else {
            console.log('call reject()...');
            reject(timeOut);
        }
    }, timeOut * 1000);
}
test(val => {
    console.log(val)
}, val => {
    console.log('timeout in ' + val + ' seconds.')
})
```

> 可以看出， `test()` 函数只关心自身的逻辑，并不关心具体的 `resolve` 和 `reject` 将如何处理结果。
> 有了执行函数，我们就可以用一个Promise对象来执行它，并在将来某个时刻获得成功或失败的结果：

``` JS
var p1 = new Promise(test);
// 当 test 中 timeOut < 1 时，p1 被赋值为 Promise {<resolved>: "200 OK"}，p1 可以成功执行 then，p2 被赋值为 Promise {<resolved>: undefined}
// 当 test 中 timeOut >= 1 时，p1 被赋值为 Promise {<rejected>: timeOut}，p2 被赋值为p1
var p2 = p1.then(function(result) {
    console.log('成功：' + result);
});
// 当 test 中 timeOut >= 1 时，p1 被赋值为 Promise {<rejected>: timeOut}，p1 执行 catch 处理失败情况
var p3 = p1.catch(function(reason) {
    console.log('失败：' + reason);
});

// 当失败时， p2 被赋值为 p1，所以用 p2 去执行 catch 处理失败是一样的，所以 Promise 对象可以使用链式调用，更简洁
new Promise(test).then(function(result) {
    console.log('成功：' + result);
}).catch(function(reason) {
    console.log('失败：' + reason);
});
```

> 可见Promise最大的好处是在异步执行的流程中，把执行代码和处理结果的代码清晰地分离了：

![Promise](https://github.com/JackZxj/my-notes/blob/master/images/RxJS/02/promise.png)

[图源：原博](https://www.liaoxuefeng.com/wiki/1022910821149312/1023024413276544)

> Promise还可以做更多的事情，比如，有若干个异步任务，需要先做任务1，如果成功后再做任务2，任何任务失败则不再继续并执行错误处理函数。
> 要串行执行这样的异步任务，不用Promise需要写一层一层的嵌套代码。有了Promise，我们只需要简单地写：
> `job1.then(job2).then(job3).catch(handleError);` 
> 其中，job1、job2和job3都是Promise对象。

除了串行执行若干异步任务外，Promise还可以并行执行异步任务，用 `Promise.all()` 实现如下：

``` JS
var p1 = new Promise(function(resolve, reject) {
    setTimeout(resolve, 500, 'P1');
});
var p2 = new Promise(function(resolve, reject) {
    setTimeout(resolve, 600, 'P2');
});
// 同时执行p1和p2，并在它们都完成后执行then:
Promise.all([p1, p2]).then(function(results) {
    console.log(results); // 获得一个Array: ['P1', 'P2']
});
```

也许有些情况下，多个并行执行的异步任务不需要要求所有请求都完成，只需要其中一个完成了就执行下一步，可以用 `Promise.race()` 实现：

``` JS
var p1 = new Promise(function(resolve, reject) {
    setTimeout(resolve, 500, 'P1');
});
var p2 = new Promise(function(resolve, reject) {
    setTimeout(resolve, 600, 'P2');
});
// 由于p1执行较快，Promise的then()将获得结果'P1'。p2仍在继续执行，但执行结果将被丢弃。
Promise.race([p1, p2]).then(function(result) {
    console.log(result); // 'P1'
});
```

#### fromEvent

> fromEvent 的第一個參數要傳入 DOM 物件，第二個參數傳入要監聽的事件名稱。上面的程式會針對 body 的 click 事件做監聽，每當點擊 body 就會印出 event。

``` JS
Rx.Observable
    .fromEvent(document.body, 'click')
    .subscribe(
        event => {
            console.log(event);
        },
        error => {
            console.log('Error: ' + error);
        },
        () => {
            console.log('done');
        },
    );
```

上面说到了这个观察 click 操作没有 complete 的时候，因此永远不会调用到 complete 方法。

##### fromEventPattern

> 要用 Event 來建立 Observable 實例還有另一個方法 fromEventPattern，這個方法是給類事件使用。所謂的類事件就是指其行為跟事件相像，同時具有註冊監聽及移除監聽兩種行為，就像 DOM Event 有 addEventListener 及 removeEventListener 一樣！

``` JS
class Producer {
    constructor() {
        this.listeners = [];
    }
    addListener(listener) {
        if (typeof(listener) === 'function') {
            this.listeners.push(listener)
        } else {
            throw new Error('listener 必須是 function')
        }
    }
    removeListener(listener) {
        this.listeners.splice(this.listeners.indexOf(listener), 1)
    }
    notify(message) {
        this.listeners.forEach(listener => {
            listener(message);
        })
    }
}
// ------- 以上都是之前的程式碼 -------- //

var egghead = new Producer();
// egghead 同時具有 註冊監聽者及移除監聽者 兩種方法

var source = Rx.Observable
    .fromEventPattern(
        (handler) => egghead.addListener(handler), // resolve
        (handler) => egghead.removeListener(handler) // reject
    );

// source 订阅了事件1
source.subscribe({
    next: function(value) {
        console.log('event 1: ' + value)
    },
    complete: function() { // 和事件监听一样不会调用到 complete
        console.log('complete!');
    },
    error: function(error) {
        console.log(error)
    }
})
// source 订阅了事件2
source.subscribe(
    event => {
        console.log('event 2: ' + event);
    },
    error => {
        console.log('Error: ' + error);
    }
);

egghead.notify('Hello! Can you hear me?');
// event 1: Hello! Can you hear me?
// event 2: Hello! Can you hear me?
```

> 這裡要注意不要直接將方法傳入，避免 this 出錯！也可以用 bind 來寫。

``` JS
Rx.Observable
    .fromEventPattern(
        egghead.addListener.bind(egghead), // 通过 bind 把 next 传入了 egghead 的事件列表
        egghead.removeListener.bind(egghead)
    )
    .subscribe(console.log) // 只传入一个 next
```

##### bind 函数

[Function.prototype.bind() - JavaScript | MDN](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Function/bind)

> `bind()` 最简单的用法是创建一个函数，不论怎么调用，这个函数都有同样的 `this` 值。JavaScript 新手经常犯的一个错误是将一个方法从对象中拿出来，然后再调用，期望方法中的 `this` 是原来的对象（比如在回调中传入这个方法）。如果不做特殊处理的话，一般会丢失原来的对象。基于这个函数，用原始的对象创建一个绑定函数，巧妙地解决了这个问题：

``` JS
this.x = 9; // 在浏览器中，this 指向全局的 "window" 对象
var module = {
    x: 81,
    getX: function() {
        return this.x;
    }
};

module.getX(); // 81

var retrieveX = module.getX;
retrieveX();
// 返回 9 - 因为函数是在全局作用域中调用的

// 创建一个新函数，把 'this' 绑定到 module 对象
// 新手可能会将全局变量 x 与 module 的属性 x 混淆
var boundGetX = retrieveX.bind(module);
boundGetX(); // 81
```

bind 的其他高级用法参见教程 [Function.prototype.bind() - JavaScript | MDN](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Function/bind)

#### empty, never, throw

**empty:** 如其名，观察的对象为空，于时直接就执行 `complete` 了。

``` JS
Rx.Observable
    .empty()
    .subscribe({
        next: function(value) {
            console.log(value);
        },
        complete: function() {
            console.log('complete!');
        },
        error: function(error) {
            console.log(error);
        }
    });
// complete!
```

**never:** 也如其名，可观察的对象永远也观察不到，所以永远也不会执行 `next` 、 `complete` 、 `error` 。

``` JS
Rx.Observable
    .never()
    .subscribe({
        next: function(value) {
            console.log(value);
        },
        complete: function() {
            console.log('complete!');
        },
        error: function(error) {
            console.log(error);
        }
    });
```

**throw:** 亦如其名，不观察到底是什么情况，直接抛错运行 `error` 就完事了。

``` JS
Rx.Observable
    .throw('I just want it be error!')
    .subscribe({
        next: function(value) {
            console.log(value);
        },
        complete: function() {
            console.log('complete!');
        },
        error: function(error) {
            console.log('Error: ' + error);
        }
    });
```

#### interval, timer

**interval:** 定时执行向 next 传入一个累加的数值。interval 需要传入一个以毫秒为单位的数值表示间隔。
`public static interval(period: number, scheduler: Scheduler): Observable` 
period: 可选，默认为 0
scheduler: 可选，默认为 async

``` JS
Rx.Observable
    .interval(1000)
    .subscribe({
        next: function(value) {
            console.log(value);
        },
        complete: function() {
            console.log('complete!');
        },
        error: function(error) {
            console.log('Error: ' + error);
        }
    });
// 0
// 1
// 2
// ...
```

**timer:** 和 interval 会定时执行向 next 传入一个累加的数值。区别在于 timer 可以控制第一个输出的延时。

`public static timer(initialDelay: number | Date, period: number, scheduler: Scheduler): Observable` 
initialDelay: 必填，若只填此项，则只输出第一个值，然后执行 complete
period: 可选，默认为 0
scheduler: 可选，默认为 async

### unsubscribe

> 其實在訂閱 observable 後，會回傳一個 subscription 物件，這個物件具有釋放資源的unsubscribe 方法，範例如下

``` JS
var subscription = Rx.Observable
    .timer(1000, 1000)
    .subscribe({
        next: function(value) {
            console.log(value);
        },
        complete: function() {
            console.log('complete!');
        },
        error: function(error) {
            console.log('Error: ' + error);
        }
    });
// 0
// 1
// 2
// ...

// 停止订阅
subscription.unsubscribe();
```

> Events observable 盡量不要用 unsubscribe ，通常我們會使用 takeUntil，在某個事件發生後來完成 Event observable，這個部份我們之後會講到！
