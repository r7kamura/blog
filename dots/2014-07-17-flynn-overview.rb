require "gviz"

node_options = { shape: "box3d", colorscheme: "blues8", style: "filled" }

Graph(:G, :digraph) do
  nodes node_options

  route :shell => :gitreceived
  edge "shell_gitreceived", label: "git-push(1)"

  route :shell => :controller
  edge "shell_controller", label: "request"

  route :gitreceived => :shelf
  edge "gitreceived_shelf", label: "upload"

  route :gitreceived => :controller
  edge "gitreceived_controller", label: "release"

  route :controller => :strowger
  edge "controller_strowger", label: "route"

  route :controller => :postgres
  edge "controller_postgres", label: "update"

  route :scheduler => :postgres
  edge "scheduler_postgres", label: "listen"

  route :scheduler => :hostA
  edge "scheduler_hostA", label: "job"

  route :hostA => [:hostB, :hostC]
  edge "hostA_hostB", label: "job"
  edge "hostA_hostC", label: "job"

  route :userAgent => :strowger
  edge "userAgent_strowger", label: "request", color: "maroon"

  route :strowger => [:containerA, :containerB, :containerC]
  edge "strowger_containerA", label: "proxy", color: "maroon"
  edge "strowger_containerB", label: "proxy", color: "maroon"
  edge "strowger_containerC", label: "proxy", color: "maroon"

  route :hostA => :shelf
  route :hostB => :shelf
  route :hostC => :shelf
  edge "hostA_shelf", label: "download"
  edge "hostB_shelf", label: "download"
  edge "hostC_shelf", label: "download"

  subgraph do
    global label: "Flynn Servers"

    subgraph do
      global label: "Cluster"

      subgraph do
        global label: "Host A"
        nodes node_options
        node :hostA, fillcolor: 3, label: "leader-host"
        node :containerA, label: "container", fillcolor: 4
        route :hostA => :containerA
        edge "hostA_containerA", label: "run"
      end

      subgraph do
        global label: "Host B"
        nodes node_options
        node :hostB, fillcolor: 3, label: "slave-host"
        node :containerB, label: "container", fillcolor: 4
        route :hostB => :containerB
        edge "hostB_containerB", label: "run"
      end

      subgraph do
        global label: "Host C"
        nodes node_options
        node :hostC, fillcolor: 3, label: "slave-host"
        node :containerC, label: "container", fillcolor: 4
        route :hostC => :containerC
        edge "hostC_containerC", label: "run"
      end
    end

    subgraph do
      global label: "Git"
      nodes node_options
      node :gitreceived, fillcolor: 3
    end

    subgraph do
      global label: "Slug"
      nodes node_options
      node :shelf, fillcolor: 3
    end

    subgraph do
      global label: "API"
      nodes node_options
      node :controller, fillcolor: 3
    end

    subgraph do
      global label: "Scheduler"
      nodes node_options
      node :scheduler, fillcolor: 3
    end

    subgraph do
      global label: "Proxy"
      nodes node_options
      node :strowger, fillcolor: 3
    end

    subgraph do
      global label: "DB"
      nodes node_options
      node :postgres, fillcolor: 3
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
