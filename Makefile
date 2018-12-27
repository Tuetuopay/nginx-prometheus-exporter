NAME = nginx-prometheus-exporter

VERSION = 0.2.1
PREFIX = nginx/$(NAME)
TAG = $(VERSION)
GIT_COMMIT = $(shell git rev-parse --short HEAD)

BUILD_DIR = build_output

ARCHS = 386 amd64 \
        arm arm64 \
        ppc64 ppc64le \
        mips mipsle mips64 mips64le \
        s390x
TARBALLS = $(ARCHS:%=$(BUILD_DIR)/$(NAME)-$(TAG)-linux-%.tar.gz)

$(NAME): test
	CGO_ENABLED=0 go build -installsuffix cgo -ldflags "-X main.version=$(VERSION) -X main.gitCommit=$(GIT_COMMIT)" -o $(NAME)

test:
	go test ./...

container:
	docker build --build-arg VERSION=$(VERSION) --build-arg GIT_COMMIT=$(GIT_COMMIT) -t $(PREFIX):$(TAG) .

push: container
	docker push $(PREFIX):$(TAG)

$(BUILD_DIR)/$(NAME)-linux-%:
	GOARCH=$* CGO_ENABLED=0 GOOS=linux go build -installsuffix cgo -ldflags "-X main.version=$(VERSION) -X main.gitCommit=$(GIT_COMMIT)" -o $(BUILD_DIR)/$(NAME)-linux-$*
$(BUILD_DIR)/$(NAME)-$(TAG)-linux-%.tar.gz: $(BUILD_DIR)/$(NAME)-linux-%
	cp -f $< $(BUILD_DIR)/$(NAME)
	tar czf $@ -C $(BUILD_DIR) $(NAME)
	-rm $(BUILD_DIR)/$(NAME)
$(BUILD_DIR)/sha256sums.txt: $(TARBALLS)
	shasum -a 256 $^ | sed "s|$(BUILD_DIR)/||" > $@

release: $(BUILD_DIR)/sha256sums.txt

clean:
	$(RM) -r $(BUILD_DIR)
	$(RM) $(NAME)

