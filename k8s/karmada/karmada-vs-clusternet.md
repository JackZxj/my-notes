[TOC]

# Karmada VS Clusternet

## Clusternet简介

**引言：** 像访问 Internet 一样轻松管理您的集群（包括公共、私有、混合、边缘等）。

![clusternet-in-a-nutshell.png](https://raw.githubusercontent.com/clusternet/clusternet/v0.10.0/docs/images/clusternet-in-a-nutshell.png)

**简述：**
Clusternet (Cluster Internet) 是一款可以帮助您像访问 Internet 一样简单地管理数以百万计的 Kubernetes 集群的开源插件。 无论集群是在公共云、私有云、混合云还是在边缘运行，Clusternet 都可以让您像是在本地运行一样管理/访问它们，无需为每个集群安装不同管理工具。
Clusternet 还可以从托管集群中将一组 API 部署或协调到多个集群。
当您的集群运行在 VPC 网络、边缘网络或防火墙后时，Clusternet 可以配置的方式设置网络隧道。
Clusternet 还提供了 Kubernetes 风格的 API，在这里你可以继续使用像是 KubeConfig 的 Kubernetes 的方式， 来访问某个托管的 Kubernetes 集群或 Kubernetes 服务。
Clusternet现在支持多个平台，包括linux/amd64、linux/arm64、linux/ppc64le、linux/s390x , linux/386 和 linux/arm;

**定位：** kubernetes的多集群管理 **插件**

**功能：**

* Kubernetes 多集群管理和治理
  * 管理在云提供商中运行的 Kubernetes 集群，例如 AWS、谷歌云、腾讯云、阿里云等
  * 管理本地 Kubernetes 集群
  * 管理任何经过认证的 Kubernetes 发行版，例如 k3s
  * 管理在边缘运行的 Kubernetes 集群
  * 父集群也可以将自己注册为子集群来运行工作负载
  * 支持 v1.17.x 到 v1.22.x 的 Kubernetes 版本
  * 使用动态 RBAC 规则访问任何托管集群
* 应用协同
  * 跨集群调度
    * 复制调度
    * 按权重静态划分调度
    * 按容量动态划分调度
  * 各种资源类型
    * Kubernetes 原生对象，如 Deployment、StatefulSet 等
    * CRD
    * helm chart，包括基于 OCI 的 Helm chart
  * 支持应用部署改写
    * 基于两阶段优先级的覆盖策略
    * 容易回滚
    * 跨集群金丝雀部署
* CLI工具
  * 提供kubectl插件，可与kubectl krew install clusternet一起安装
  * 与kubectl保持一致的用户体验
  * 创建/更新/监视/删除多群集资源
  * 与任何子集群交互，与本地集群相同
* Client-go支持
  * 通过项目提供的包装器可以保持和原生client-go无缝的使用体验

**架构：**

![clusternet-arch.png](https://raw.githubusercontent.com/clusternet/clusternet/v0.10.0/docs/images/clusternet-arch.png)

## 安装方式比较

<table class="wrapped confluenceTable">
    <colgroup>
        <col>
        <col>
        <col>
    </colgroup>
    <tbody>
            <tr>
                    <th class="confluenceTh"><br></th>
                    <th class="confluenceTh">Karmada</th>
                    <th class="confluenceTh">Clusternet</th>
            </tr>
<tr>
<td class="confluenceTd">Helm</td>
<td class="confluenceTd">

```BASH
$ helm repo add karmada-charts https://raw.githubusercontent.com/karmada-io/karmada/master/charts

# all in one, 如果需要安装不同的组件需要修改相关的values.yaml
$ helm --namespace karmada-system upgrade -i karmada karmada-charts/karmada --version=v1.2.0 --create-namespace
```

</td>
<td class="confluenceTd">

```BASH
$ helm repo add clusternet https://clusternet.github.io/charts

# install hub in master cluster
$ helm install clusternet-hub -n clusternet-system --create-namespace clusternet/clusternet-hub
# install scheduler in master cluster
$ helm install clusternet-scheduler -n clusternet-system --create-namespace clusternet/clusternet-scheduler

# install agent in member cluster
$ helm install clusternet-agent -n clusternet-system --create-namespace \
--set parentURL=<Parent-url> \
--set registrationToken=<token> \
clusternet/clusternet-agent
```

</td>
</tr>
            <tr>
                    <td class="confluenceTd">cli 安装</td>
                    <td class="confluenceTd">kubectl karmada init</td>
                    <td class="confluenceTd">不支持</td>
            </tr>
            <tr>
                    <td class="confluenceTd">operator 安装</td>
                    <td class="confluenceTd">非官方项目，未来可能会贡献给官方: https://github.com/DaoCloud/karmada-operator </td>
                    <td class="confluenceTd">不支持</td>
            </tr>
            <tr>
                    <td class="confluenceTd">裸金属部署（无k8s）</td>
                    <td class="confluenceTd">可以完全脱离k8s独立部署: https://karmada.io/zh/docs/installation/install-binary </td>
                    <td class="confluenceTd">有限的支持，由于 clusternet-hub 是作为 AA 服务运行，需要确保存在一个作为管理侧的k8s集群，且其 apiserver 可以访问到 clusternet-hub 服务。</td>
            </tr>
            <tr>
                    <td class="confluenceTd">demo for kind</td>
                    <td class="confluenceTd">https://github.com/karmada-io/karmada/blob/master/hack/local-up-karmada.sh </td>
                    <td class="confluenceTd">https://github.com/clusternet/clusternet/blob/main/hack/local-running.sh </td>
            </tr>
<tr>
<td class="confluenceTd">components</td>
<td class="confluenceTd">

* etcd 存储
* karmada-aggregated-apiserver 聚合API，处理cluster对象及proxy等
* karmada-apiserver 原生APIserver，作为入口
* karmada-controller-manager Karmada自己的控制器
* karmada-descheduler 调度器，用于取消及重调度
* karmada-kube-controller-manager 原生控制器，处理原生数据
* karmada-scheduler 调度器
* karmada-scheduler-estimator-MEMBER_NAME 调度估算器，用于计算成员集群的状态，供调度器评估选择集群
* karmada-search 搜索跨集群资源，内置缓存
* karmada-webhook 数据校验等
* karmada-agent 仅Pull模式使用

</td>
<td class="confluenceTd">

* clusternet-hub AA服务器，负责管理资源，clusternet服务的入口
* clusternet-scheduler 调度器
* clusternet-agent 每个被管集群都需要部署的agent

</td>
</tr>
</tbody>
</table>

总结：

* Karmada支持的安装方式更多，项目更为独立，可支持完全脱离k8s独立部署；但由于其组件较多，可配置的属性较多，安装所需的资源也较多，安装相对复杂
* Clusternet目前主要使用Helm安装，组件少，安装快捷；但由于依赖K8s环境，在裸金属上的安装使用不是很方便

## 纳管集群的方式

<table class="wrapped confluenceTable">
    <colgroup>
        <col>
        <col>
        <col>
    </colgroup>
    <tbody>
        <tr>
            <th class="confluenceTh"><br></th>
            <th class="confluenceTh">Karmada</th>
            <th class="confluenceTh">Clusternet</th>
        </tr>
        <tr>
            <td class="confluenceTd">管理侧主动发起纳管（Push）</td>
            <td class="confluenceTd">
                <p>支持</p>
                <p><br></p>
                <p>管理侧纳管流程（该流程可使用Karmadactl一键完成）：</p>
                <ol>
                    <li>在成员集群中创建两个SA，一个用于管理，一个用于统一鉴权（RBAC）</li>
                    <li>在成员集群创建管理员权限的ClusterRole</li>
                    <li>在成员集群创建ClusterRoleBinding，绑定用于管理的SA与ClusterRole</li>
                    <li>将两个SA所生成的Secret在管理侧复制一份</li>
                    <li>在管理侧使用上述的复制Secret名称及被管集群的IP信息等创建CLuster对象，管理侧则使用管理的SA token来进行集群管理</li>
                </ol>
            </td>
            <td class="confluenceTd">官方没有明确支持，但是可以通过把agent部署到管理侧，由agent远程管理集群来实现Push模式</td>
        </tr>
        <tr>
            <td class="confluenceTd">管理侧被动进行纳管（Pull）</td>
            <td class="confluenceTd">
                <p>支持</p>
                <p><br></p>
                <p>成员集群注册到管理侧流程：</p>
                <ol>
                    <li>在成员集群内创建用于统一鉴权的SA</li>
                    <li>使用管理侧的Kubeconfig创建成员集群的Lease命名空间（如果不存在的话），然后创建Pull模式的Cluster对象，以及将上述SA生成的Secret在管理侧复制一份。之后就完成了注册，使用该管理侧config监听管理侧变化。</li>
                </ol>
            </td>
            <td class="confluenceTd">
                <p>支持</p>
                <p><br></p>
                <p>Clusternet支持两类token注册集群：</p>
                <ol>
                    <li>更通用的SA secret token，需要在管理侧创建该SA及其ClusterRoleBinding（不需要绑定管理员权限）</li>
                    <li>更简短的bootstrap.kubernetes.io/token类型的secret
                        token，但不是所有的APIServer都会开放此类型的认证，需要在管理侧创建该Secret</li>
                </ol>
                <p><br></p>
                <p>成员集群注册到管理侧流程：</p>
                <ol>
                    <li>使用上述的两类token之一在成员集群运行agent，agent会使用该agent访问管理侧集群，使用当前集群的ID、agent名称、同步模式等信息在上面创建一个ClusterRegistrationRequest的资源，等待管理侧发现并同意该请求。</li>
                    <li>管理侧的hub如果发现了新的请求，则会为其创建一个专用的namespace（名称随机），按照ClusterRegistrationRequest上报的信息创建该集群的ManagedCluster资源，在上述专用ns里创建一个SA（名称随机），创建ClusterRole（非管理员，仅用于注册、查看secret及访问代理连接）和ClusterRoleBinding（绑定前述的SA），创建Role（拥有ns内全部权限）和RoleBinding（绑定前述的SA），最后将SA生成的Secret token、CA证书、专有ns、ManagedCluster名称、同意接入更新到ClusterRegistrationRequest的status中</li>
                    <li>agent每隔5秒刷新一次ClusterRegistrationRequest的状态，发现请求被同意后就能通过status里的token、CA构建client访问管理侧</li>
                </ol>
            </td>
        </tr>
        <tr>
            <td class="confluenceTd">成员集群的唯一性判断</td>
            <td class="confluenceTd">按照注册时声明的Name判断唯一</td>
            <td class="confluenceTd">agent部署后会创建一个lease，该lease不会被自动删除，因此只要该lease没被删除，agent注册上来的集群ID就不变</td>
        </tr>
        <tr>
            <td class="confluenceTd">其他</td>
            <td class="confluenceTd"><br></td>
<td class="confluenceTd">

clusternet注册成功后会显示当前集群的注册模式，分为双向（Dual）模式，pull模式和push模式，具体所支持的功能略有区别：

* Push意味着父集群中的所有资源变化都会被自动同步、推送并应用到子集群clusternet-hub。
* Pull意味着clusternet-agent将监视，同步并将所有资源更改从父集群应用到子集群。
* Dual结合了Push和Pull模式。强烈推荐使用此模式（默认）。

注：此Push/Pull非注册用的，单指应用同步的模式，与karmada所指的Push/Pull模式注册不同

</td>
        </tr>
    </tbody>
</table>

总结：

* Karmada支持两种集群注册模式，可以覆盖更多的多集群场景；但是其Pull模式需要用到管理侧的Kubeconfig，如果在成员集群中泄露，则可能存在风险（或者可以基于RBAC签一个小权限的kubeconfig把风险降低至clusternet级别，需要验证)
* Clusternet主要支持Pull模式进行集群注册，Push模式可以讨巧实现；其注册时相对更安全，因为agent只有单个namespace内的权限，即使泄露了也不会对整个管理侧造成影响

## 跨集群应用部署

<table class="wrapped confluenceTable">
    <colgroup>
        <col>
        <col>
        <col>
    </colgroup>
    <tbody>
        <tr>
            <th class="confluenceTh"><br></th>
            <th class="confluenceTh">Karmada</th>
            <th class="confluenceTh">Clusternet</th>
        </tr>
        <tr>
            <td class="confluenceTd">基本资源部署</td>
            <td class="confluenceTd">
                <div class="content-wrapper">
                    <p>支持任意k8s支持的实体资源（原生资源或者crd）</p>
                    <p><br></p>
                    <p>部署流程：</p>
                    <ol>
                        <li>创建需要多集群部署的资源的元数据（如deployment、svc等）</li>
                        <li>创建多集群部署的策略（PropagationPolicy），可选创建覆写策略（OverridePolicy）</li>
                    </ol>
                    <p><br></p>
                    <p>内部流程：</p>
                    <p><img class="confluence-embedded-image confluence-external-resource"
                             alt="concept"
                             height="519"
                             width="571"
                             src="../../images/Karmada-summary/workflow.png"
                             data-image-src="../../images/Karmada-summary/workflow.png">
                    </p>
                </div>
                <p><br></p>
                <p>原理：</p>
                <ol>
                    <li>karmada使用原生的APIServer作为入口，使用独立的ETCD作为存储，因此创建k8s资源只会创建到Karmada内，而不会影响宿主集群。</li>
                    <li>Karmada自己的controller检测到策略资源变动时，根据策略声明创建或者修改相应的副产物资源（ResourceBinding、Work）</li>
                    <li>push模式则controller主动推送部署；pull模式agent监听work并在本地部署</li>
                </ol>
            </td>
            <td class="confluenceTd">
                <div class="content-wrapper">
                    <p>支持任意k8s支持的实体资源（原生资源或者crd）</p>
                    <p><br></p>
                    <p>部署流程：</p>
                    <ol>
                        <li>创建需要多集群部署的资源的元数据（如deployment、svc等）</li>
                        <li>创建多集群部署的策略（Subscription），可选创建覆写策略（Localization）</li>
                    </ol>
                    <p><br></p>
                    <p>内部流程：</p>
                </div>
                <p><img class="confluence-embedded-image confluence-external-resource"
                         alt="clusternet-apps-concepts.png"
                         height="400"
                         src="https://raw.githubusercontent.com/clusternet/clusternet/v0.10.0/docs/images/clusternet-apps-concepts.png"
                         data-image-src="https://raw.githubusercontent.com/clusternet/clusternet/v0.10.0/docs/images/clusternet-apps-concepts.png">
                </p>
                <p><br></p>
                <p>原理：</p>
                <ol>
                    <li>clusternet使用AA接入到宿主集群，使用宿主集群的etcd作为存储；为了不影响原生资源的使用，使用专用的kubectl-clusternet命令行工具或者通过包装过的client-go进行跨集群资源的增删改查（本质上是拦截请求，将其转发到clusternet-hub的shadowAPI），元数据会生成Manifest资源（未在上述中体现，是副产物资源）存储到宿主集群的etcd。在读取这些元数据时，可以既可以直接读取Manifest资源，也可以通过shadowAPI获取（如果是cli获取的话，通过shadowAPI获取的结果更直观，因为跟原生的结果一样）</li>
                    <li>Clusternet的的相关controller按照上述的流程进行跨集群资源的处理</li>
                    <li>agent通过访问管理侧ns内的Description资源，读取其中的元数据，将其部署到agent所在的集群</li>
                </ol>
            </td>
        </tr>
        <tr>
            <td class="confluenceTd">Chart部署</td>
            <td class="confluenceTd">不支持（截至2022年8月）</td>
            <td class="confluenceTd">支持，以CRD的形式声明了一个helm chart对象，然后将其按照上述的流程分发，由agent去拉取helm chart，并进行部署</td>
        </tr>
        <tr>
            <td class="confluenceTd">动态部署</td>
            <td class="confluenceTd">
                <p>支持更丰富的动态部署能力</p>
                <ol>
                    <li>复制部署</li>
                    <li>分散部署（支持按集群/按组/按地域等）
                        <ol>
                            <li>聚合部署</li>
                            <li>静态比例</li>
                            <li>自动动态比例</li>
                        </ol>
                    </li>
                </ol>
                <p><br></p>
                <p><br></p>
                <p>可支持的部署选项：</p>
                <ul>
                    <li>PropagateDeps工作负载的依赖（configmap、secret）自动跟随工作负载部署到目标集群，不需要手动指定需要部署的集群</li>
                    <li>Placement
                        <ul>
                            <li>ClusterAffinity 集群亲和性
                                <ul>
                                    <li>LabelSelector 按标签选择</li>
                                    <li>FieldSelector 按指定域选择</li>
                                    <li>ClusterNames 直接选中的集群列表</li>
                                    <li>ExcludeClusters 排除的集群列表</li>
                                </ul>
                            </li>
                            <li>ClusterTolerations 可以给集群打上污点以排除集群调度，这个参数可以指定容忍的污点列表
                            </li>
                            <li>SpreadConstraints 传播约束
                                <ul>
                                    <li>SpreadByField 集群有provider、region、zone属性，部署的目标集群可以按照这些属性进行分组，最小组单位为cluster（默认值），与SpreadByLabel不兼容</li>
                                    <li>SpreadByLabel 按照集群的标签进行分组</li>
                                    <li>MaxGroups 部署的资源最多下发到几个组</li>
                                    <li>MinGroups 部署的资源最少下发到几个组，默认为1</li>
                                </ul>
                            </li>
                            <li>ReplicaScheduling 副本调度
                                <ul>
                                    <li>ReplicaSchedulingType 确定在 karmada 传播资源时如何调度副本。支持Duplicated和Divided两种策略。Duplicated将相同的副本从资源复制到每个候选成员集群（当前HCP版本使用的规则）。Divided根据有效候选成员集群的数量将副本划分为多个部分，每个集群的确切副本由ReplicaDivisionPreference 确定</li>
                                    <li>ReplicaDivisionPreference支持Aggregated和Weighted两种策略。Aggregated将副本尽可能少地集中到若干集群中，同时在划分期间尊重集群的资源可用性。Weighted根据WeightPreference 按权重划分副本。</li>
                                    <li>WeightPreference
                                        <ul>
                                            <li>StaticWeightList 静态地指定集群的权重，支持按标签、按域、按名称选择集群</li>
                                            <li>DynamicWeight 目前仅支持AvailableReplicas，会依据当前集群可用的副本数按比例划分，如总共需要12个副本，A可用副本6，B可用副本12，C可用副本18，则按比例分配给A2个副本，B4个副本，C6个副本</li>
                                        </ul>
                                    </li>
                                </ul>
                            </li>
                        </ul>
                    </li>
                </ul>
                <p><br></p>
            </td>
            <td class="confluenceTd">
                <p>支持基础的动态部署能力</p>
                <ol>
                    <li>复制部署</li>
                    <li>分散部署
                        <ol>
                            <li>静态比例</li>
                            <li>动态比例</li>
                        </ol>
                    </li>
                </ol>
                <p><br></p>
                <p><br></p>
                <p>可支持的部署选项：</p>
                <ul>
                    <li>
                        <p>SchedulingStrategy 部署方式，复制（Replication，默认值）或者分散（Dividing）</p>
                    </li>
                    <li>
                        <p><span>DividingScheduling</span></p>
                        <ul>
                            <li>分散部署的类型，Static或Dynami：Static按照声明的集群的权重，权重越大分配越多；Dynamic按照下面的DynamicDividing规则来分配</li>
                            <li>DynamicDividing
                                <ul>
                                    <li>Strategy 分散部署的模式，Spread或Binpack，当前仅支持Spread模式，即按照集群的剩余资源可供副本运行的数量决定，剩余的资源越多，分配到的副本数越多</li>
                                    <li><span>TopologySpreadConstraints
                                            分散调度约束，仅支持Spread模式，<strong>当前版本尚未实装</strong></span>
                                    </li>
                                    <li><span>PreferredClusters
                                            倾向性调度，类似于Karmada的Aggregated类型，<strong>当前版本尚未实装</strong></span>
                                    </li>
                                    <li><span>MinClusters
                                                最少调度到几个集群，<strong>当前版本尚未实装</strong></span>
                                    </li>
                                    <li><span>MaxClusters
                                                最多调度到几个集群，<strong>当前版本尚未实装</strong></span>
                                    </li>
                                </ul>
                            </li>
                        </ul>
                    </li>
                </ul>
            </td>
        </tr>
        <tr>
            <td class="confluenceTd">资源状态采集</td>
            <td class="confluenceTd">所有下发的资源的状态会采集到Work对象中，对于有副本的应用如Deployment，会统计总的副本情况更新到Deployment的status里</td>
            <td class="confluenceTd">所有下发的资源的状态会采集到Description对象中，不会统计副本数并更新到元数据</td>
        </tr>
        <tr>
            <td class="confluenceTd">分类</td>
            <td class="confluenceTd">
                <p>支持ClusterPropagationPolicy与普通PropagationPolicy两类传播策略，但不是分级的，二者处于同级</p>
                <p><br></p>
                <p>ClusterPropagationPolicy 表示将一组资源传播到一个或多个集群的集群范围的策略。与只能在自己的命名空间中传播资源的
                    PropagationPolicy 不同，ClusterPropagationPolicy
                    能够传播集群级别的资源和系统保留以外的任何命名空间中的资源。系统保留的命名空间有：karmada-system、karmada-cluster、karmada-es-*。
                </p>
            </td>
            <td class="confluenceTd">Subscription不区分Namespace，可以分发的资源可以为任意namespace</td>
        </tr>
    </tbody>
</table>

总结：

* Karmada支持的部署策略更丰富，但不支持Chart下发
* Clusternet支持的部署策略较为基础，但实现了Chart的部署

## 跨集群应用覆写配置

<table class="wrapped confluenceTable">
    <colgroup>
        <col>
        <col>
        <col>
    </colgroup>
    <tbody>
        <tr>
            <th class="confluenceTh"><br></th>
            <th class="confluenceTh">Karmada</th>
            <th class="confluenceTh">Clusternet</th>
        </tr>
        <tr>
            <td class="confluenceTd">覆写配置</td>
            <td class="confluenceTd">内置了镜像修改、Command修改、Args修改器，支持任意修改元数据，但仅支持JSONPatch格式的修改</td>
            <td class="confluenceTd">无内置修改器，支持任意修改元数据，普通的k8s资源支持JSONPatch和MergePatch两种修改模式；针对Chart类型支持Helm模式的修改，可修改Chart元数据，也可以修改values.yaml</td>
        </tr>
        <tr>
            <td class="confluenceTd">分类</td>
            <td class="confluenceTd">支持ClusterOverridePolicy和普通OverridePolicy两类覆写策略，但两者不分级</td>
            <td class="confluenceTd">支持Globalization和Localization两级，Localization会覆盖Globalization
            </td>
        </tr>
        <tr>
            <td class="confluenceTd">优先级支持</td>
            <td class="confluenceTd">不支持</td>
            <td class="confluenceTd">
                <p>支持0-1000的优先级，默认值为500，低优先级的会被高优先级的覆盖。</p>
                <p><br></p>
                <p>举例：（-&gt;表示会被覆盖）</p>
                <p>Globalization (优先级 : 100) -&gt; Globalization (优先级: 600) -&gt; Localization
                    (优先级: 100) -&gt; Localization (优先级 500)</p>
            </td>
        </tr>
        <tr>
            <td class="confluenceTd">生效配置</td>
            <td class="confluenceTd">立即生效，后创建的会覆盖前者</td>
            <td class="confluenceTd">
                <p>支持两种生效策略：</p>
                <ul>
                    <li>ApplyNow 将立即为匹配的对象应用覆盖，包括那些已经填充的对象。</li>
                    <li>ApplyLater 为默认覆盖策略，只会在下次更新时应用覆盖匹配的对象（包括更新在 Subscription、HelmChart 等）或新创建的对象。</li>
                </ul>
            </td>
        </tr>
    </tbody>
</table>

总结：

* Clusternet支持更多的覆写策略，并且可配置性更高；相对的来说上手的难度较高
* Karmada支持基本的覆写策略，但是缺少优先级、生效配置等。

## 高级功能支持情况

<table class="wrapped confluenceTable">
    <colgroup>
        <col>
        <col>
        <col>
    </colgroup>
    <tbody>
        <tr>
            <th class="confluenceTh"><br></th>
            <th class="confluenceTh">Karmada</th>
            <th class="confluenceTh">Clusternet</th>
        </tr>
        <tr>
            <td class="confluenceTd">MultiClusterService</td>
            <td class="confluenceTd">已支持，内置mcs控制器</td>
            <td class="confluenceTd">未支持，预计后续几个版本内会支持</td>
        </tr>
        <tr>
            <td class="confluenceTd">跨集群Ingress</td>
            <td class="confluenceTd">已支持，官方支持，具体可参考<a href="./Karmada-Multi-Cluster-Ingress.md">Karmada中的MCI</a></td>
            <td class="confluenceTd">未支持</td>
        </tr>
        <tr>
            <td class="confluenceTd">跨集群HPA</td>
            <td class="confluenceTd">已支持，通过动态调度实现</td>
            <td class="confluenceTd">未支持</td>
        </tr>
        <tr>
            <td class="confluenceTd">多集群信息汇总及查询</td>
            <td class="confluenceTd">
                <p>未支持</p>
                <p>在v1.3.0中通过search组件支持，它允许用户访问多个集群中的资源，就像访问单个集群的资源一样。无论资源是否由Karmada管理，用户都可以通过利用代理从控制面读取到。</p>
            </td>
            <td class="confluenceTd">未支持</td>
        </tr>
        <tr>
            <td class="confluenceTd">控制面代理访问成员集群</td>
            <td class="confluenceTd">
<div class="content-wrapper">
<p>已支持，通过aggregated-apiserver支持代理访问子集群，并且该功能支持RBAC权限隔离。（仅支持Push模式，pull模式需要通过ANP来访问）</p>
<p><br></p>

```BASH
# 默认的karmada apiserver的kubeconfig已创建好rbac了，可以直接获取proxy
$ kubectl get --raw /apis/cluster.karmada.io/v1alpha1/clusters/member1/proxy/api/v1/namespaces/default/services/kubernetes
{"kind":"Service","apiVersion":"v1","metadata":{"name":"kubernetes","namespace":"default",...}

# 或者可以创建一个新的config，把server地址设置成
# https://karmada-apiserver-ip:5443/apis/cluster.karmada.io/v1alpha1/clusters/{clustername}/proxy
# 即可通过该config使用原生kubeconfig或者client-go访问
```

</div>
</td>
<td colspan="1" class="confluenceTd">
<div class="content-wrapper">
<p>已支持，需要使用子集群的kubeconfig作为认证。另外也支持proxy将子集群的服务暴露到控制面。</p>
<p>（虽然官方没有明确说明支持rbac，但我感觉应该可以支持的，本质上也是通过hub与agent的websocket通道实现通信的，需要后续验证）</p>

```BASH
# 当前已纳管的子集群
$ kubectl get mcls -A | grep child1
clusternet-dg7d9   child1   bb678514-2f99-4411-8bf7-b4aa64059f08   Dual        v1.22.0      True     13d

# 子集群的kubeconfig，内网IP也可以
$ cat child1.config | grep server
server: https://127.0.0.1:6443

# 通过代理访问子集群的服务，需要id和child-kubeconfig两个额外参数
$ kubectl clusternet get svc --cluster-id=bb678514-2f99-4411-8bf7-b4aa64059f08 --child-kubeconfig child1.config -A
NAMESPACE     NAME           TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                  AGE
default       kubernetes     ClusterIP   10.96.0.1      &lt;none&gt;        443/TCP                  13d
foo           my-nginx-svc   ClusterIP   10.96.62.155   &lt;none&gt;        80/TCP                   13d
kube-system   kube-dns       ClusterIP   10.96.0.10     &lt;none&gt;        53/UDP,53/TCP,9153/TCP   13d

# 此功能需要最新版本（v0.7.0及以上）的kubectl-clusternet工具
$ kubectl clusternet port-forward --namespace default \
--cluster-id=c1a5e75c-9e38-4279-b1c9-2345e612b9e5 \
--child-kubeconfig=./child-kubeconfig \
svc/my-nginx-test 8080:80
Forwarding from 127.0.0.1:8080 -&gt; 80
Forwarding from [::1]:8080 -&gt; 80
Handling connection for 8080
# 此时另一个窗口可以访问本地端口来代理到远程集群
$ curl http://localhost:8080
```

</div>
</td>
        </tr>
        <tr>
            <td class="confluenceTd">成员集群间代理访问</td>
            <td class="confluenceTd">可以通过mcs实现多集群服务间访问，依赖于网络畅通</td>
            <td class="confluenceTd">当前版本子集群可以通过访问hub的proxy来访问另一个成员集群的服务。</td>
        </tr>
        <tr>
            <td class="confluenceTd">跟其他k8s周边生态的兼容性</td>
            <td class="confluenceTd">具有较好的兼容性，支持Istio、Argo CD、Flux、Gatekeeper(OPA)、Kyverno等项目</td>
            <td class="confluenceTd">原生支持helm chart，其他项目未有相关的实践</td>
        </tr>
        <tr>
            <td class="confluenceTd">统一鉴权</td>
            <td class="confluenceTd">可通过proxy的rbac规则实现</td>
            <td class="confluenceTd">理论上可以通过proxy的rbac规则实现</td>
        </tr>
        <tr>
            <td class="confluenceTd">社区活跃度</td>
<td class="confluenceTd">

截至2022年9月1日

* star: 2482
* fork: 502
* watch: 56
* issue: 678
  * open: 137
  * closed: 541
* pull request: 1772
  * open: 58
  * closed: 1714

第一次发布开源版本时间：2020/12/4

已发布版本数：26

</td>
<td class="confluenceTd">

截至2022年9月1日

* star: 948
* fork: 224
* watch: 28
* issue: 137
  * open: 31
  * closed: 106
* pull request: 330
  * open: 8
  * closed: 322

第一次发布开源版本时间：2021/3/28

已发布版本数：12
</td>
        </tr>
        <tr>
            <td class="confluenceTd">商业应用</td>
            <td class="confluenceTd">
                华为云MCP、VIPkid、浦发银行、等等。。。
                <br> 
                <img src="data:image/png;base64,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" ></td>
            <td class="confluenceTd">腾讯云 TDCC</td>
        </tr>
        <tr>
            <td class="confluenceTd">版本支持</td>
<td class="confluenceTd">

|                        | Kubernetes 1.15 | Kubernetes 1.16 | Kubernetes 1.17 | Kubernetes 1.18 | Kubernetes 1.19 | Kubernetes 1.20 | Kubernetes 1.21 | Kubernetes 1.22 | Kubernetes 1.23 |
|------------------------|-----------------|-----------------|-----------------|-----------------|-----------------|-----------------|-----------------|-----------------|-----------------|
| Karmada v0.9           | ✓               | ✓               | ✓               | ✓               | ✓             | ✓               | ✓               | ✓               | ✓               |
| Karmada v0.10          | ✓               | ✓               | ✓               | ✓               | ✓             | ✓               | ✓               | ✓               | ✓               |
| Karmada v1.0           | ✓               | ✓               | ✓               | ✓               | ✓             | ✓               | ✓               | ✓               | ✓               |
| Karmada HEAD (master)  | ✓               | ✓               | ✓               | ✓               | ✓             | ✓               | ✓               | ✓               | ✓               |

Key:
* `✓` Karmada and the Kubernetes version are exactly compatible.
* `+` Karmada has features or API objects that may not be present in the Kubernetes version.
* `-` The Kubernetes version has features or API objects that Karmada can't use.

</td>
<td class="confluenceTd">

|                        | Kubernetes 1.17 | Kubernetes 1.18 | Kubernetes 1.19 - 1.22 |
|------------------------|-----------------|-----------------|-----------------|
| Clusternet v0.5        | *               | *               | ✓             |
| Clusternet v0.6        | *               | ✓               | ✓             |
| Clusternet v0.7        | *               | ✓               | ✓             |
| Clusternet HEAD (main) | *               | ✓               | ✓             |

Key:
* `✓` Clusternet is compatible with this Kubernetes version.
* `*` Clusternet has no guarantees to support this Kubernetes version. More compatible tests will be needed.

</td>
        </tr>

</tbody>
</table>

总结：

* Karmada的周边生态及所支持组件、功能更丰富
* Clusternet的功能较少，有待后续逐步完善



