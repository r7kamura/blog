require "gviz"

node_options = { shape: "box3d", colorscheme: "blues8", style: "filled" }

Graph(:G, :digraph) do
  nodes node_options

  route :shell => :gitreceived
  edge "shell_gitreceived", label: "git-push(1)"

  route :gitreceived => :shelf
  edge "gitreceived_shelf", label: "upload slug"

  route :gitreceived => :controller
  edge "gitreceived_controller", label: "release"

  route :controller => :strowger
  edge "controller_strowger", label: "add route"

  route :controller => :postgres
  edge "controller_postgres", label: "store release"

  route :controller => [:hostA, :hostB]
  edge "controller_hostA", label: "deploy"
  edge "controller_hostB", label: "deploy"

  route :userAgent => :strowger
  edge "userAgent_strowger", label: "request", color: "maroon"

  route :strowger => [:hostA, :hostB]
  edge "strowger_hostA", label: "proxy", color: "maroon"
  edge "strowger_hostB", label: "proxy", color: "maroon"

  subgraph do
    global label: "Cloud"

    subgraph do
      global label: "Cluster"

      subgraph do
        global label: "Host A"
        nodes node_options
        node :hostA, fillcolor: 3, label: "host"
        node :discoverdA, label: "discoverd"
        node :etcdA, label: "etcd"
        node :containerA, label: "container", fillcolor: 4
        route :hostA => :containerA
        route :hostA => :discoverdA
        route :discoverdA => :etcdA
        edge "hostA_containerA", color: "maroon", label: "deploy & proxy"
      end

      subgraph do
        global label: "Host B"
        nodes node_options
        node :hostB, fillcolor: 3, label: "host"
        node :discoverdB, label: "discoverd"
        node :etcdB, label: "etcd"
        node :containerB, label: "container", fillcolor: 4
        route :hostB => :containerB
        route :hostB => :discoverdB
        route :discoverdB => :etcdB
        edge "hostB_containerB", color: "maroon", label: "deploy & proxy"
      end
    end

    subgraph do
      global label: "Git server"
      nodes node_options
      node :gitreceived, fillcolor: 3
      node :discoverdG, label: "discoverd"
      node :etcdG, label: "etcd"
      route :gitreceived => :discoverdG
      route :discoverdG => :etcdG
    end

    subgraph do
      global label: "Shelf server"
      nodes node_options
      node :shelf, fillcolor: 3
      node :discoverdS, label: "discoverd"
      node :etcdS, label: "etcd"
      route :shelf => :discoverdS
      route :discoverdS => :etcdS
    end

    subgraph do
      global label: "API server"
      nodes node_options
      node :controller, fillcolor: 3
      node :discoverdC, label: "discoverd"
      node :etcdC, label: "etcd"
      route :controller => :discoverdC
      route :discoverdC => :etcdC
    end

    subgraph do
      global label: "Reverse proxy"
      nodes node_options
      node :strowger, fillcolor: 3
      node :discoverdR, label: "discoverd"
      node :etcdR, label: "etcd"
      route :strowger => :discoverdR
      route :strowger => :etcdR
      route :discoverdR => :etcdR
    end

    subgraph do
      global label: "Postgres"
      nodes node_options
      node :postgres, fillcolor: 3
      node :discoverdP, label: "discoverd"
      node :etcdP, label: "etcd"
      route :postgres => :discoverdP
      route :discoverdP => :etcdP
    end
  end

  subgraph do
    global label: "Internet"

    subgraph do
      global label: "Developer"
      nodes node_options
      node :shell, fillcolor: 2, label: "shell"
      node :shell
    end

    subgraph do
      global label: "User"
      nodes node_options
      node :userAgent, fillcolor: 2, label: "user agent"
      node :userAgent
    end
  end

  save "images/2014-07-17/flynn-overview", :png
end
