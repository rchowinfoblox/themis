SRCROOT := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
BUILDPATH = $(SRCROOT)/build
COVEROUT=$(SRCROOT)/cover.out
COVERTMP=/tmp/cover.out

AT = cd $(SRCROOT)
RM = rm -fv
GOBUILD = go build -v
#GOBUILD = CGO_ENABLED=0 go build -v
GOFMTCHECK = test -z `gofmt -w -s *.go | tee /dev/stderr`
GOTEST = go test -v
COVER = $(GOTEST) -coverprofile=$(COVERTMP) -covermode=atomic
JOINCOVER = cat $(COVERTMP) >> $(COVEROUT)
GOTESTRACE = $(COVER) -race && $(JOINCOVER)
GOBENCH = $(GOTEST) -run=BypassAllTestsAndRunOnlyBenchmarks -bench=
GOBENCHALL = $(GOBENCH).

BUILDTOOL := infoblox/buildtool:v6
REGISTRY := docker.inca.infoblox.com/

.PHONY: all
all: fmt build test bench

.PHONY: build-dir
build-dir:
	mkdir -p $(BUILDPATH)

.PHONY: bootstrap
bootstrap:
	glide install --strip-vendor

.PHONY: clean
clean:
	@$(RM) $(COVEROUT)
	@$(RM) -fr $(BUILDPATH)

.PHONY: fmt
fmt: fmt-pdp fmt-pdp-yast fmt-pdp-jast fmt-pdp-jcon fmt-pdpctrl-client fmt-papcli fmt-pep fmt-pepcli fmt-pepcli-requests fmt-pepcli-test fmt-pepcli-perf fmt-pdpserver fmt-plugin fmt-egen

.PHONY: build
build: build-dir build-pepcli build-papcli build-pdpserver build-plugin build-egen

.PHONY: test
test: cover-out test-pdp test-pdp-yast test-pdp-jast test-pdp-jcon test-pep test-plugin

.PHONY: bench
bench: bench-pep bench-pdpserver

.PHONY: cover-out
cover-out:
	echo > $(COVEROUT)

# Per package format targets
.PHONY: fmt-pdp
fmt-pdp:
	@echo "Checking PDP format..."
	@$(AT)/pdp && $(GOFMTCHECK)

.PHONY: fmt-pdp-yast
fmt-pdp-yast:
	@echo "Checking PDP YAST format..."
	@$(AT)/pdp/ast/yast && $(GOFMTCHECK)

.PHONY: fmt-pdp-jast
fmt-pdp-jast:
	@echo "Checking PDP JAST format..."
	@$(AT)/pdp/ast/jast && $(GOFMTCHECK)

.PHONY: fmt-pdp-jcon
fmt-pdp-jcon:
	@echo "Checking PDP JCon format..."
	@$(AT)/pdp/jcon && $(GOFMTCHECK)

.PHONY: fmt-pdpctrl-client
fmt-pdpctrl-client:
	@echo "Checking PDP control client library format..."
	@$(AT)/pdpctrl-client && $(GOFMTCHECK)

.PHONY: fmt-papcli
fmt-papcli:
	@echo "Checking PAP CLI format..."
	@$(AT)/papcli && $(GOFMTCHECK)

.PHONY: fmt-pep
fmt-pep:
	@echo "Checking PEP client library format..."
	@$(AT)/pep && $(GOFMTCHECK)

.PHONY: fmt-pepcli
fmt-pepcli:
	@echo "Checking PEP CLI format..."
	@$(AT)/pepcli && $(GOFMTCHECK)

.PHONY: fmt-pepcli-requests
fmt-pepcli-requests:
	@echo "Checking PEP CLI requests package format..."
	@$(AT)/pepcli/requests && $(GOFMTCHECK)

.PHONY: fmt-pepcli-test
fmt-pepcli-test:
	@echo "Checking PEP CLI test package format..."
	@$(AT)/pepcli/test && $(GOFMTCHECK)

.PHONY: fmt-pepcli-perf
fmt-pepcli-perf:
	@echo "Checking PEP CLI perf package format..."
	@$(AT)/pepcli/perf && $(GOFMTCHECK)

.PHONY: fmt-pdpserver
fmt-pdpserver:
	@echo "Checking PDP server format..."
	@$(AT)/pdpserver && $(GOFMTCHECK)

.PHONY: fmt-plugin
fmt-plugin:
	@echo "Checking PE-CoreDNS Middleware format..."
	@$(AT)/contrib/coredns/policy && $(GOFMTCHECK)
	@$(AT)/contrib/coredns/policy/dnstap && $(GOFMTCHECK)

.PHONY: fmt-egen
fmt-egen:
	@echo "Checking EGen format..."
	@$(AT)/egen && $(GOFMTCHECK)

# Per package build targets
.PHONY: build-pepcli
build-pepcli: build-dir
	$(AT)/pepcli && $(GOBUILD) -o $(BUILDPATH)/pepcli

.PHONY: build-papcli
build-papcli: build-dir
	$(AT)/papcli && $(GOBUILD) -o $(BUILDPATH)/papcli

.PHONY: build-pdpserver
build-pdpserver: build-dir
	$(AT)/pdpserver && $(GOBUILD) -o $(BUILDPATH)/pdpserver

.PHONY: build-plugin
build-plugin: build-dir
	$(AT)/contrib/coredns/policy && $(GOBUILD)
	$(AT)/contrib/coredns/policy/dnstap && $(GOBUILD)

.PHONY: build-egen
build-egen: build-dir
	$(AT)/egen && $(GOBUILD) -o $(BUILDPATH)/egen

.PHONY: test-pdp
test-pdp: cover-out
	$(AT)/pdp && $(GOTESTRACE)

.PHONY: test-pdp-yast
test-pdp-yast: cover-out
	$(AT)/pdp/ast/yast && $(GOTESTRACE)

.PHONY: test-pdp-jast
test-pdp-jast: cover-out
	$(AT)/pdp/ast/jast && $(GOTESTRACE)

.PHONY: test-pdp-jcon
test-pdp-jcon: cover-out
	$(AT)/pdp/jcon && $(GOTESTRACE)

.PHONY: test-pep
test-pep: build-pdpserver cover-out
	$(AT)/pep && $(GOTESTRACE)

.PHONY: test-plugin
test-plugin: cover-out
	$(AT)/contrib/coredns/policy && $(GOTESTRACE)
	$(AT)/contrib/coredns/policy/dnstap && $(GOTESTRACE)

.PHONY: bench-pep
bench-pep: build-pdpserver
	$(AT)/pep && $(GOBENCH)\(Benchmark.*PolicySet\)\|\(BenchmarkStreamingClient\)

.PHONY: bench-pdpserver
bench-pdpserver:
	$(AT)/pdpserver && $(GOBENCHALL)

.PHONY: docker-pdpserver
docker-pdpserver: build/pdpserver
	docker build -f pdpserver/Dockerfile -t $(REGISTRY)pdpserver . \
	&& docker push $(REGISTRY)pdpserver

