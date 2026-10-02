# Raceboat Plugin Development Guide for Agents

This guide provides comprehensive instructions for designing, implementing, building, and testing Raceboat transport component plugins. It is optimized for software agents performing implementation-build-test loops.

---

## 1. Architecture Overview

### 1.1 Plugin Types

Raceboat supports **decomposed channels** composed of three component types:
- **Transport**: Handles data movement through a third-party service (e.g., AWS S3, Mastodon, Redis)
- **Encoding**: Transforms raw bytes into service-appropriate content (e.g., base64, image steganography)
- **User Model**: Schedules when actions (fetch/post) occur to mimic realistic traffic patterns

### 1.2 Transport Component Responsibilities

The transport component implements `ITransportComponent` and is responsible for:

| Responsibility | Key Methods |
|----------------|-------------|
| **Link lifecycle** | `createLink`, `loadLinkAddress`, `createLinkFromAddress`, `destroyLink` |
| **Action parameter negotiation** | `getActionParams` |
| **Content queuing** | `enqueueContent`, `dequeueContent` |
| **Action execution** | `doAction` (fetch/post) |
| **User input collection** | `onUserInputReceived` (via `sdk->requestPluginUserInput`) |
| **Status reporting** | `sdk->onLinkStatusChanged`, `sdk->onPackageStatusChanged`, `sdk->onReceive`, `sdk->onEvent` |

### 1.3 Key Interfaces

```cpp
// Core transport interface (raceboat/include/race/decomposed/ITransportComponent.h)
class ITransportComponent : public IComponentBase {
    virtual TransportProperties getTransportProperties() = 0;
    virtual LinkProperties getLinkProperties(const LinkID &linkId) = 0;
    
    // Link management
    virtual ComponentStatus createLink(RaceHandle handle, const LinkID &linkId) = 0;
    virtual ComponentStatus loadLinkAddress(RaceHandle handle, const LinkID &linkId, const std::string &linkAddress) = 0;
    virtual ComponentStatus loadLinkAddresses(RaceHandle handle, const LinkID &linkId, const std::vector<std::string> &linkAddress) = 0;
    virtual ComponentStatus createLinkFromAddress(RaceHandle handle, const LinkID &linkId, const std::string &linkAddress) = 0;
    virtual ComponentStatus destroyLink(RaceHandle handle, const LinkID &linkId) = 0;
    
    // Message handling
    virtual std::vector<EncodingParameters> getActionParams(const Action &action) = 0;
    virtual ComponentStatus enqueueContent(const EncodingParameters &params, const Action &action, const std::vector<uint8_t> &content) = 0;
    virtual ComponentStatus dequeueContent(const Action &action) = 0;
    virtual ComponentStatus doAction(const std::vector<RaceHandle> &handles, const Action &action) = 0;
};

// SDK provided to transport (raceboat/include/race/decomposed/ITransportSdk.h)
class ITransportSdk : public virtual IComponentSdkBase {
    virtual ChannelProperties getChannelProperties() = 0;
    virtual ChannelResponse onLinkStatusChanged(RaceHandle handle, const LinkID &linkId, LinkStatus status, const LinkParameters &params) = 0;
    virtual ChannelResponse onPackageStatusChanged(RaceHandle handle, PackageStatus status) = 0;
    virtual ChannelResponse onEvent(const Event &event) = 0;
    virtual ChannelResponse onReceive(const LinkID &linkId, const EncodingParameters &params, const std::vector<uint8_t> &bytes) = 0;
    virtual RaceHandle requestPluginUserInput(const std::string &key, const std::string &prompt, bool required) = 0;
    virtual void updateState(ComponentState state) = 0;
    virtual std::string getActivePersona() = 0;
};
```

---

## 2. Transport Component Implementation Patterns

### 2.1 Base Class Structure

Follow the pattern used by `SkyhookTransport` and `PluginCommsTwoSixStubTransport`:

```cpp
// MyTransport.h
class MyTransport : public ITransportComponent {
public:
    explicit MyTransport(ITransportSdk *sdk, const std::string &roleName);
    
    // Required overrides
    virtual ComponentStatus onUserInputReceived(RaceHandle handle, bool answered, const std::string &response) override;
    virtual TransportProperties getTransportProperties() override;
    virtual LinkProperties getLinkProperties(const LinkID &linkId) override;
    virtual ComponentStatus createLink(RaceHandle handle, const LinkID &linkId) override;
    virtual ComponentStatus loadLinkAddress(RaceHandle handle, const LinkID &linkId, const std::string &linkAddress) override;
    virtual ComponentStatus loadLinkAddresses(RaceHandle handle, const LinkID &linkId, const std::vector<std::string> &linkAddress) override;
    virtual ComponentStatus createLinkFromAddress(RaceHandle handle, const LinkID &linkId, const std::string &linkAddress) override;
    virtual ComponentStatus destroyLink(RaceHandle handle, const LinkID &linkId) override;
    virtual std::vector<EncodingParameters> getActionParams(const Action &action) override;
    virtual ComponentStatus enqueueContent(const EncodingParameters &params, const Action &action, const std::vector<uint8_t> &content) override;
    virtual ComponentStatus dequeueContent(const Action &action) override;
    virtual ComponentStatus doAction(const std::vector<RaceHandle> &handles, const Action &action) override;

protected:
    virtual std::shared_ptr<Link> createLinkInstance(const LinkID &linkId, const LinkAddress &address, const LinkProperties &properties, bool isCreator);
    
    // Helper methods
    bool preLinkCreate(const std::string &logPrefix, RaceHandle handle, const LinkID &linkId, LinkSide invalidRoleLinkSide);
    ComponentStatus postLinkCreate(const std::string &logPrefix, RaceHandle handle, const LinkID &linkId, const std::shared_ptr<Link> &link, LinkStatus linkStatus);
    void handleUserInputResponse(RaceHandle handle, bool answered, const std::string &response);

private:
    ITransportSdk *sdk;
    std::string racePersona;
    ChannelProperties channelProperties;
    LinkProperties defaultLinkProperties;
    LinkMap links;
    bool ready = false;
    // User input handles...
};

// Entry points (required for plugin loading)
extern "C" EXPORT ITransportComponent* createTransport(const std::string &transport, ITransportSdk *sdk, const std::string &roleName, const PluginConfig &pluginConfig);
extern "C" EXPORT void destroyTransport(ITransportComponent *component);
```

### 2.2 LinkAddress Design

Define a `LinkAddress` struct with JSON serialization for your service:

```cpp
// LinkAddress.h
struct LinkAddress {
    // Service-specific fields (e.g., for S3: region, buckets, object UUIDs)
    std::string region;
    std::string fetchBucket;
    std::string initialFetchObjUuid;
    std::string postBucket;
    std::string initialPostObjUuid;
    int openObjects{1};
    int maxTries{120};
    bool singleReceive{false};
    // Add your service-specific fields here
};

// JSON serialization (REQUIRED for link address exchange)
void to_json(nlohmann::json &destJson, const LinkAddress &src);
void from_json(const nlohmann::json &srcJson, LinkAddress &dest);
```

### 2.3 Link Class Pattern

Each link runs a dedicated action thread for async fetch/post operations:

```cpp
// Link.h
class Link {
public:
    Link(const LinkID &linkId, const LinkAddress &address, const LinkProperties &properties, bool isCreator, MyTransport *transport, ITransportSdk *sdk);
    virtual ~Link();
    
    virtual LinkID getId() const;
    virtual const LinkProperties &getProperties() const;
    virtual ComponentStatus enqueueContent(uint64_t actionId, const std::vector<uint8_t> &content);
    virtual ComponentStatus dequeueContent(uint64_t actionId);
    virtual ComponentStatus fetch(std::vector<RaceHandle> handles);  // Note: Skyhook uses handles, stub doesn't
    virtual ComponentStatus post(std::vector<RaceHandle> handles, uint64_t actionId);
    virtual void start();
    virtual void shutdown();

protected:
    virtual std::string postOnActionThread(const std::string &postObjUuid, const std::vector<RaceHandle> &handles, uint64_t actionId);
    virtual bool postToService(const std::vector<uint8_t> &message, const std::string &postObjUuid);
    virtual std::string fetchOnActionThread(const std::string &fetchObjUuid);
    
    ITransportSdk *sdk;
    MyTransport *transport;
    LinkID linkId;
    LinkProperties properties;
    LinkAddress address;
    
    struct QueuedAction { bool post; std::vector<RaceHandle> handles; uint64_t actionId; };
    std::thread thread;
    std::atomic<bool> isShutdown{false};
    std::mutex mutex;
    std::condition_variable conditionVariable;
    std::deque<QueuedAction> actionQueue;
    std::unordered_map<uint64_t, std::vector<uint8_t>> contentQueue;
    
    void runActionThread();
    void updatePackageStatus(const std::vector<RaceHandle> &handles, PackageStatus status);
};
```

**Action Thread Loop** (`runActionThread`):
```cpp
void Link::runActionThread() {
    std::string fetchObjUuid = address.initialFetchObjUuid;
    std::string postObjUuid = address.initialPostObjUuid;
    
    while (!isShutdown) {
        std::unique_lock<std::mutex> lock(mutex);
        conditionVariable.wait(lock, [this] { return isShutdown || !actionQueue.empty(); });
        
        if (isShutdown) break;
        
        auto action = actionQueue.front();
        actionQueue.pop_front();
        lock.unlock();
        
        if (action.post) {
            postObjUuid = postOnActionThread(postObjUuid, action.handles, action.actionId);
        } else {
            fetchObjUuid = fetchOnActionThread(fetchObjUuid);
        }
    }
}
```

### 2.4 User Input Handling

Request required parameters at construction time:

```cpp
MyTransport::MyTransport(ITransportSdk *sdk, const std::string &roleName) :
    sdk(sdk),
    racePersona(sdk->getActivePersona()),
    channelProperties(sdk->getChannelProperties()),
    defaultLinkProperties(createDefaultLinkProperties(channelProperties)),
    // Request user inputs - handles stored for response matching
    regionReqHandle(sdk->requestPluginUserInput("region", "What region is the service in?", true).handle),
    credentialReqHandle(sdk->requestPluginUserInput("credential", "Enter API credential:", true).handle),
    // ... more inputs
{}
```

Handle responses in `onUserInputReceived`:

```cpp
ComponentStatus MyTransport::onUserInputReceived(RaceHandle handle, bool answered, const std::string &response) {
    if (handle == regionReqHandle) {
        regionReqHandle = NULL_RACE_HANDLE;
        if (answered) region = response;
        else region = "default-region";
    }
    // ... handle other inputs
    
    // Mark ready when all inputs collected
    if (regionReqHandle == NULL_RACE_HANDLE && credentialReqHandle == NULL_RACE_HANDLE) {
        ready = true;
        sdk->updateState(COMPONENT_STATE_STARTED);
    }
    return COMPONENT_OK;
}
```

### 2.5 Action Parameter Negotiation

```cpp
std::vector<EncodingParameters> MyTransport::getActionParams(const Action &action) {
    ActionJson actionParams = nlohmann::json::parse(action.json);
    switch (actionParams.type) {
        case ACTION_FETCH:
            return {};  // Fetch typically needs no encoding params
        case ACTION_POST:
            return {{actionParams.linkId, "*/*", true, {}}};  // MIME type, encode flag, extra JSON
        default:
            sdk->updateState(COMPONENT_STATE_FAILED);
            return {};
    }
}
```

### 2.6 Content Queuing

```cpp
ComponentStatus MyTransport::enqueueContent(const EncodingParameters &params, const Action &action, const std::vector<uint8_t> &content) {
    if (content.empty()) return COMPONENT_OK;
    
    ActionJson actionParams = nlohmann::json::parse(action.json);
    switch (actionParams.type) {
        case ACTION_POST:
            return links.get(params.linkId)->enqueueContent(action.actionId, content);
        default:
            return COMPONENT_OK;
    }
}

ComponentStatus MyTransport::dequeueContent(const Action &action) {
    ActionJson actionParams = nlohmann::json::parse(action.json);
    if (actionParams.type == ACTION_POST) {
        return links.get(actionParams.linkId)->dequeueContent(action.actionId);
    }
    return COMPONENT_OK;
}
```

### 2.7 Action Execution (doAction)

```cpp
ComponentStatus MyTransport::doAction(const std::vector<RaceHandle> &handles, const Action &action) {
    ActionJson actionParams = nlohmann::json::parse(action.json);
    switch (actionParams.type) {
        case ACTION_FETCH:
            return links.get(actionParams.linkId)->fetch(std::move(handles));
        case ACTION_POST:
            return links.get(actionParams.linkId)->post(std::move(handles), action.actionId);
        default:
            return COMPONENT_ERROR;
    }
}
```

### 2.8 Link Creation/Loading Flow

```cpp
ComponentStatus MyTransport::createLink(RaceHandle handle, const LinkID &linkId) {
    if (!preLinkCreate(logPrefix, handle, linkId, LS_LOADER)) return COMPONENT_ERROR;
    
    // Generate address for new link (creator side)
    LinkAddress address;
    address.region = region;
    address.fetchBucket = bucket;
    address.initialFetchObjUuid = generateUniqueId("fetch");
    address.postBucket = bucket;
    address.initialPostObjUuid = generateUniqueId("post");
    
    auto link = createLinkInstance(linkId, address, defaultLinkProperties, true /*isCreator*/);
    return postLinkCreate(logPrefix, handle, linkId, link, LINK_CREATED);
}

ComponentStatus MyTransport::loadLinkAddress(RaceHandle handle, const LinkID &linkId, const std::string &linkAddress) {
    if (!preLinkCreate(logPrefix, handle, linkId, LS_CREATOR)) return COMPONENT_ERROR;
    
    LinkAddress address = nlohmann::json::parse(linkAddress);
    auto link = createLinkInstance(linkId, address, defaultLinkProperties, false /*isCreator*/);
    return postLinkCreate(logPrefix, handle, linkId, link, LINK_LOADED);
}
```

**Address Flipping** (for bidirectional links): In `Link` constructor, if `isCreator`, swap fetch/post fields so each side fetches what the other posts.

---

## 3. Build System (CMake)

### 3.1 Project Structure

```
my-plugin/
├── CMakeLists.txt              # Top-level
├── source/
│   ├── CMakeLists.txt          # Component targets
│   ├── manifest.json           # Plugin manifest
│   ├── common/                 # Shared code
│   │   ├── Link.h/.cpp
│   │   ├── LinkAddress.h/.cpp
│   │   ├── LinkMap.h/.cpp
│   │   ├── JsonTypes.h
│   │   └── log.h/.cpp
│   ├── transport/              # Transport component
│   │   ├── MyTransport.h/.cpp
│   │   └── CMakeLists.txt
│   ├── user-model/             # User model (optional)
│   └── encoding/               # Encoding (optional)
└── test/                       # Unit tests
    └── source/
        ├── CMakeLists.txt
        └── transport/
            ├── TestMyTransport.cpp
            └── TestLink.cpp
```

### 3.2 Top-Level CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.20)
project(my-plugin LANGUAGES CXX)

set(CMAKE_MODULE_PATH /opt/race/race-cmake-modules)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

set(BUILD_VERSION "" CACHE STRING "Version of the plugin being built")
if("${BUILD_VERSION}" STREQUAL "")
    message(SEND_ERROR "Missing or empty BUILD_VERSION argument")
endif()

include(race/clang-format)
include(race/coverage)
include(race/lint)
include(race/test-targets)
include(race/valgrind)
include(race/warnings)

setup_project_test_targets(my-plugin UNIT)
setup_project_format_targets(my-plugin)

add_subdirectory(source)
```

### 3.3 Source CMakeLists.txt

```cmake
# Common dependencies
if(ANDROID)
    find_library(LIB_CURL curl)
    find_package(Boost COMPONENTS filesystem system REQUIRED)
    find_library(LIB_CPPREST cpprest)
    find_library(LIB_LOG log)
    set(LIB_DEPS ${LIB_CURL} Boost::system Boost::filesystem ${LIB_CPPREST} ${LIB_LOG} ${RACE_JAVA_SHIMS})
else()
    find_library(LIB_CURL curl)
    find_library(LIB_CPPREST cpprest)
    find_library(LIB_CRYPTO crypto)
    find_library(LIB_SSL ssl)
    find_library(RACE_SDK_COMMON raceSdkCommon HINTS ENV LD_LIBRARY_PATH)
    set(LIB_DEPS ${RACE_SDK_COMMON} ${LIB_CURL} ${LIB_CPPREST} ${LIB_CRYPTO} ${LIB_SSL})
endif()

set(PLUGIN_BASE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../kit)
set(COMMON_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/common)

function(setup_component_target)
    cmake_parse_arguments(COMPONENT "" "TARGET" "SOURCES" ${ARGN})
    add_library(${COMPONENT_TARGET} SHARED ${COMPONENT_SOURCES})
    target_include_directories(${COMPONENT_TARGET} PRIVATE ${COMMON_SRC_DIR})
    target_link_libraries(${COMPONENT_TARGET} ${LIB_DEPS})
    target_compile_definitions(${COMPONENT_TARGET} PUBLIC BUILD_VERSION="${BUILD_VERSION}")
    set_target_properties(${COMPONENT_TARGET} PROPERTIES CXX_VISIBILITY_PRESET hidden NO_SONAME ON)
    
    # Install to kit artifacts
    if(ANDROID)
        # Android artifact copying...
    else()
        add_custom_command(TARGET ${COMPONENT_TARGET} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory ${PLUGIN_BASE_DIR}/artifacts/${NODE_TYPE}-client/PluginMyPlugin
            COMMAND ${CMAKE_COMMAND} -E make_directory ${PLUGIN_BASE_DIR}/artifacts/${NODE_TYPE}-server/PluginMyPlugin
            COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${COMPONENT_TARGET}> ${PLUGIN_BASE_DIR}/artifacts/${NODE_TYPE}-client/PluginMyPlugin/
            COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${COMPONENT_TARGET}> ${PLUGIN_BASE_DIR}/artifacts/${NODE_TYPE}-server/PluginMyPlugin/
        )
    endif()
endfunction()

# Manifest handling (copy to artifacts)
# ... (see skyhook/source/CMakeLists.txt for full manifest logic)

add_subdirectory(transport)
add_subdirectory(user-model)  # if needed
add_subdirectory(encoding)    # if needed
```

### 3.4 Transport CMakeLists.txt

```cmake
setup_component_target(
    TARGET MyTransport
    SOURCES
        MyTransport.cpp
        ../common/Link.cpp
        ../common/LinkAddress.cpp
        ../common/LinkMap.cpp
        ../common/log.cpp
        # Service-specific sources (e.g., S3Manager.cpp)
)
# Add service-specific dependencies (e.g., AWS SDK)
```

### 3.5 Building

```bash
# Inside raceboat-plugin-builder container
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=/opt/race/race-cmake-modules/toolchains/linux-x86_64.toolchain.cmake -DBUILD_VERSION=1.0.0
make -j$(nproc)

# Or use the provided build script
./build_artifacts_in_docker_image.sh
```

---

## 4. Manifest and Composition

### 4.1 Manifest Structure (manifest.json)

```json
{
  "plugins": [
    {
      "file_path": "PluginMyPlugin",
      "plugin_type": "comms",
      "file_type": "shared_library",
      "node_type": "any",
      "shared_library_path": "libMyTransport.so",
      "transports": ["myTransport"],
      "usermodels": [],
      "encodings": []
    }
  ],
  "channel_properties": {
    "myComposition": {
      "bootstrap": false,
      "channelGid": "myComposition",
      "connectionType": "CT_INDIRECT",
      "creatorExpected": { "send": {...}, "receive": {...} },
      "loaderExpected": { "send": {...}, "receive": {...} },
      "linkDirection": "LD_BIDI",
      "transmissionType": "TT_UNICAST",
      "sendType": "ST_STORED_ASYNC",
      "reliable": false,
      "isFlushable": false,
      "duration_s": -1,
      "period_s": -1,
      "mtu": -1,
      "maxLinks": 1000,
      "supported_hints": ["polling_interval_ms"],
      "roles": [{ "roleName": "default", "linkSide": "LS_BOTH" }]
    }
  },
  "compositions": [
    {
      "id": "myComposition",
      "transport": "myTransport",
      "usermodel": "someUserModel",
      "encodings": ["base64"]
    }
  ]
}
```

### 4.2 Key Channel Properties for Indirect Transports

| Property | Typical Value | Description |
|----------|---------------|-------------|
| `connectionType` | `CT_INDIRECT` | Uses third-party service |
| `transmissionType` | `TT_UNICAST` or `TT_MULTICAST` | One-to-one or one-to-many |
| `sendType` | `ST_STORED_ASYNC` | Stored async (not real-time) |
| `linkDirection` | `LD_BIDI` | Bidirectional |
| `supported_hints` | `["polling_interval_ms", "after"]` | Hints for user model scheduling |

---

## 5. Testing Patterns

### 5.1 Unit Test Structure

Use GoogleTest with mock SDK (`race/mocks/MockTransportSdk.h`):

```cpp
// TestMyTransport.cpp
#include <gtest/gtest.h>
#include <race/mocks/MockTransportSdk.h>
#include "MyTransport.h"
#include "MockLink.h"  // Mock for Link class

class TestedTransport : public MyTransport {
public:
    ITransportSdk *sdk;
    std::unordered_map<LinkID, std::shared_ptr<MockLink>> &mockLinks;
    
    TestedTransport(ITransportSdk *sdk, std::unordered_map<LinkID, std::shared_ptr<MockLink>> &mockLinks) :
        MyTransport(sdk, "default"), sdk(sdk), mockLinks(mockLinks) {}
    
    std::shared_ptr<Link> createLinkInstance(const LinkID &linkId, const LinkAddress &address, const LinkProperties &properties, bool isCreator) override {
        auto link = std::make_shared<MockLink>(linkId, address, properties, sdk);
        mockLinks[linkId] = link;
        return link;
    }
};

class TestMyTransport : public ::testing::Test {
public:
    ::testing::NiceMock<MockTransportSdk> sdk;
    ChannelProperties channelProps;
    std::unordered_map<LinkID, std::shared_ptr<MockLink>> mockLinks;
    
    TestMyTransport() {
        channelProps.maxLinks = 10;
        channelProps.currentRole.linkSide = LS_CREATOR;
        ON_CALL(sdk, getActivePersona()).WillByDefault(::testing::Return("test-persona"));
        ON_CALL(sdk, getChannelProperties()).WillByDefault(::testing::Invoke([this]() { return channelProps; }));
    }
    
    std::unique_ptr<MyTransport> createTransport() {
        return std::make_unique<TestedTransport>(&sdk, mockLinks);
    }
};

TEST_F(TestMyTransport, should_create_link) {
    channelProps.currentRole.linkSide = LS_CREATOR;
    auto transport = createTransport();
    EXPECT_CALL(sdk, onLinkStatusChanged(1u, "LinkID_1", LINK_CREATED, ::testing::_));
    ASSERT_EQ(COMPONENT_OK, transport->createLink(1u, "LinkID_1"));
}

TEST_F(TestMyTransport, should_enqueue_content_for_post) {
    auto transport = createTransport();
    ASSERT_EQ(COMPONENT_OK, transport->createLink(1u, "LinkID_1"));
    std::vector<uint8_t> content{0x31, 0x41, 0x59};
    EXPECT_CALL(*mockLinks["LinkID_1"], enqueueContent(42, content)).WillOnce(::testing::Return(COMPONENT_OK));
    Action action{8675309, 42, "{\"linkId\":\"LinkID_1\",\"type\":\"post\"}"};
    EncodingParameters encodeParams{"LinkID_1", "*/*", true, ""};
    ASSERT_EQ(COMPONENT_OK, transport->enqueueContent(encodeParams, action, content));
}
```

### 5.2 Link Unit Tests

Test the action thread and service interactions:

```cpp
// TestLink.cpp
class LinkToTestActions : public Link {
public:
    using Link::Link;
    MOCK_METHOD(std::string, fetchOnActionThread, (const std::string &fetchObjUuid), (override));
    MOCK_METHOD(std::string, postOnActionThread, (const std::string &postObjUuid, const std::vector<RaceHandle> &handles, uint64_t actionId), (override));
};

TEST_F(TestLinkActions, fetch_succeeds) {
    auto link = createLink();
    EXPECT_CALL(*link, fetchOnActionThread("obj-1")).WillOnce(::testing::Return("obj-2"));
    link->start();
    ASSERT_EQ(COMPONENT_OK, link->fetch({}));
    waitForActionToBeExecuted();
}
```

### 5.3 Service Interaction Tests (Phase 3)

Create standalone test binaries for service API validation:

```cpp
// test_service_interaction.cpp
int main() {
    // Initialize service client with credentials
    // Test: store small data blob
    // Test: retrieve data blob
    // Test: delete data blob
    // Verify round-trip integrity
}
```

---

## 6. Integration Testing

### 6.1 Docker-Based Integration Test

```bash
# Build plugin
./build_artifacts_in_docker_image.sh

# Run server (creator)
docker run --rm -it --name=rbserver --network=raceboat-network \
    -v $(pwd)/kits:/server-kits \
    raceboat:latest bash -c \
    'bridge-distro --passphrase test --dir /server-kits \
    --recv-channel=myComposition --send-channel=myComposition \
    --param myComposition.param1=value1 \
    --recv-address="{\"field\": \"value\"}"'

# Run client (loader)
docker run --rm -it --name=rbclient --network=raceboat-network \
    -v $(pwd)/kits:/client-kits \
    raceboat:latest bash -c \
    'echo "test message" | race-cli --dir /client-kits \
    --send-channel=myComposition --recv-channel=myComposition \
    --send-address="{\"field\": \"value\"}"'
```

### 6.2 Test Checklist

- [ ] Link creation on both sides
- [ ] Link address exchange (creator → loader)
- [ ] Content enqueue → post → fetch → receive cycle
- [ ] Multiple simultaneous links
- [ ] Link destruction cleanup
- [ ] Error handling (service unavailable, auth failure, rate limits)
- [ ] Retry logic with `maxTries`
- [ ] User input prompting works
- [ ] Component state transitions (INIT → STARTED → FAILED)

---

## 7. Common Patterns and Gotchas

### 7.1 Multiple Simultaneous Links

- Use `LinkMap` (thread-safe `unordered_map<LinkID, shared_ptr<Link>>`)
- Each link has independent `LinkAddress` and action thread
- `maxLinks` from `channelProperties` limits concurrent links

### 7.2 Credential Management

- **NEVER hardcode credentials**
- Use `sdk->requestPluginUserInput()` for all secrets
- Credentials passed via `--param` at runtime or environment variables
- Reuse tokens from Phase 3 service interaction tests

### 7.3 Content Encoding Boundary

- Transport receives **already-encoded** bytes via `enqueueContent`
- Transport does **not** handle encoding/decoding
- Encoding component handles MIME type negotiation
- `getActionParams` tells encoding what params to use

### 7.4 Action JSON Format

```json
// Fetch action
{"linkId": "link-123", "type": "fetch"}

// Post action
{"linkId": "link-123", "type": "post"}
```

Parse with `ActionJson` from `JsonTypes.h`.

### 7.5 Event Emission

Emit events for user model coordination:

```cpp
nlohmann::json eventJson = {
    {"linkId", linkId},
    {"actionId", actionId},
    {"status", "posted"}  // or "fetched", "failed"
};
sdk->onEvent({eventJson.dump()});
```

### 7.6 Persistent Storage

Use `PersistentStorageHelpers.h` for saving state across restarts:

```cpp
// Save
psh::saveValue(sdk, "key:" + identifier, value);

// Load
auto value = psh::readValue(sdk, "key:" + identifier, defaultValue);
```

### 7.7 Logging

```cpp
#include "log.h"
logDebug("Debug message");
logInfo("Info message");
logWarning("Warning message");
logError("Error message");
logPrefix += linkId + ": ";  // Add context in link methods
```

### 7.8 Error Handling

- Return `COMPONENT_OK` for success
- Return `COMPONENT_ERROR` for recoverable errors
- Return `COMPONENT_FATAL` for unrecoverable errors (triggers component restart)
- Call `sdk->updateState(COMPONENT_STATE_FAILED)` on fatal errors

---

## 8. Implementation Checklist (RACEGEN Phases)

### Phase 1: High-Level Design
- [ ] Assess third-party service API capabilities
- [ ] Document addressing methods (how recipient finds data)
- [ ] Document content types (what data forms service accepts)
- [ ] Rank by innocuousness (adversary perspective)
- [ ] Output: `HIGH_LEVEL_DESIGN.md`

### Phase 2: Precise Design
- [ ] Authentication requirements (sender/receiver)
- [ ] Data visibility (public vs credential-gated)
- [ ] Content types + action names (store/retrieve)
- [ ] Bidirectional strategy (single channel vs two unidirectional)
- [ ] Multicast vs unicast
- [ ] Data retention duration
- [ ] Safe post-retrieval deletion
- [ ] Output: `PRECISE_DESIGN.md`

### Phase 3: Service Interaction Stubs
- [ ] Stub code for each service action
- [ ] Unit tests for stubs
- [ ] Credential/token iteration until POC works
- [ ] Store/retrieve arbitrary data blob
- [ ] Output: `SERVICE_INTERACTION_DESIGN.md` + working stubs

### Phase 4: Transport Component
- [ ] Implement `ITransportComponent` using stubs
- [ ] Parameter ingestion via `requestUserInput`
- [ ] Content queuing via `enqueueContent`
- [ ] Multiple link management with address create/load
- [ ] User Model action generation integration
- [ ] Component Integration document (User Model + Encoding specs)
- [ ] Build and run integration tests
- [ ] Fix errors until passing

---

## 9. Reference Implementations

Study these existing transports in the codebase:

| Transport | Location | Key Characteristics |
|-----------|----------|---------------------|
| **Skyhook Public User** | `code/skyhook/source/public-user-transport/` | Client-side, no auth, S3 GET only |
| **Skyhook Account Holder** | `code/skyhook/source/account-holder-transport/` | Server-side, AWS auth, S3 PUT/GET, bucket management |
| **TwoSix Stub** | `code/decomposed-exemplars/source/transport/` | Simple HTTP whiteboard, hashtag-based addressing |

### Key Files to Reference

- `code/skyhook/source/common/SkyhookTransport.h/.cpp` - Base transport with user input handling
- `code/skyhook/source/common/Link.h/.cpp` - Link with action thread, S3 HTTP operations
- `code/skyhook/source/common/LinkAddress.h/.cpp` - S3-specific address with JSON serialization
- `code/decomposed-exemplars/source/transport/PluginCommsTwoSixStubTransport.h/.cpp` - Simpler reference
- `code/decomposed-exemplars/source/transport/Link.h/.cpp` - Whiteboard-based link implementation
- `code/raceboat/include/race/decomposed/*.h` - All interface definitions

---

## 10. Quick Start Template

### 10.1 Minimal Transport Header

```cpp
// MyTransport.h
#ifndef MY_TRANSPORT_H
#define MY_TRANSPORT_H

#include <ITransportComponent.h>
#include <LinkProperties.h>
#include "LinkAddress.h"
#include "LinkMap.h"

class MyTransport : public ITransportComponent {
public:
    explicit MyTransport(ITransportSdk *sdk, const std::string &roleName);
    
    // IComponentBase
    ComponentStatus onUserInputReceived(RaceHandle handle, bool answered, const std::string &response) override;
    
    // ITransportComponent
    TransportProperties getTransportProperties() override;
    LinkProperties getLinkProperties(const LinkID &linkId) override;
    ComponentStatus createLink(RaceHandle handle, const LinkID &linkId) override;
    ComponentStatus loadLinkAddress(RaceHandle handle, const LinkID &linkId, const std::string &linkAddress) override;
    ComponentStatus loadLinkAddresses(RaceHandle handle, const LinkID &linkId, const std::vector<std::string> &linkAddress) override;
    ComponentStatus createLinkFromAddress(RaceHandle handle, const LinkID &linkId, const std::string &linkAddress) override;
    ComponentStatus destroyLink(RaceHandle handle, const LinkID &linkId) override;
    std::vector<EncodingParameters> getActionParams(const Action &action) override;
    ComponentStatus enqueueContent(const EncodingParameters &params, const Action &action, const std::vector<uint8_t> &content) override;
    ComponentStatus dequeueContent(const Action &action) override;
    ComponentStatus doAction(const std::vector<RaceHandle> &handles, const Action &action) override;

protected:
    std::shared_ptr<Link> createLinkInstance(const LinkID &linkId, const LinkAddress &address, const LinkProperties &properties, bool isCreator) override;
    
    bool preLinkCreate(const std::string &logPrefix, RaceHandle handle, const LinkID &linkId, LinkSide invalidRoleLinkSide);
    ComponentStatus postLinkCreate(const std::string &logPrefix, RaceHandle handle, const LinkID &linkId, const std::shared_ptr<Link> &link, LinkStatus linkStatus);
    void handleUserInputResponse(RaceHandle handle, bool answered, const std::string &response);

private:
    ITransportSdk *sdk;
    std::string racePersona;
    ChannelProperties channelProperties;
    LinkProperties defaultLinkProperties;
    LinkMap links;
    bool ready = false;
    // User input handles...
};

extern "C" EXPORT ITransportComponent* createTransport(const std::string &transport, ITransportSdk *sdk, const std::string &roleName, const PluginConfig &pluginConfig);
extern "C" EXPORT void destroyTransport(ITransportComponent *component);

#endif
```

### 10.2 Minimal Link Header

```cpp
// Link.h
#ifndef MY_LINK_H
#define MY_LINK_H

#include <ComponentTypes.h>
#include <LinkProperties.h>
#include <SdkResponse.h>
#include "LinkAddress.h"

class MyTransport;
class ITransportSdk;

class Link {
public:
    Link(const LinkID &linkId, const LinkAddress &address, const LinkProperties &properties, bool isCreator, MyTransport *transport, ITransportSdk *sdk);
    virtual ~Link();
    
    LinkID getId() const;
    const LinkProperties &getProperties() const;
    ComponentStatus enqueueContent(uint64_t actionId, const std::vector<uint8_t> &content);
    ComponentStatus dequeueContent(uint64_t actionId);
    ComponentStatus fetch(std::vector<RaceHandle> handles);
    ComponentStatus post(std::vector<RaceHandle> handles, uint64_t actionId);
    void start();
    void shutdown();

protected:
    virtual std::string postOnActionThread(const std::string &postObjUuid, const std::vector<RaceHandle> &handles, uint64_t actionId);
    virtual bool postToService(const std::vector<uint8_t> &message, const std::string &postObjUuid);
    virtual std::string fetchOnActionThread(const std::string &fetchObjUuid);
    
    ITransportSdk *sdk;
    MyTransport *transport;
    LinkID linkId;
    LinkProperties properties;
    LinkAddress address;
    
    struct QueuedAction { bool post; std::vector<RaceHandle> handles; uint64_t actionId; };
    std::thread thread;
    std::atomic<bool> isShutdown{false};
    std::mutex mutex;
    std::condition_variable conditionVariable;
    std::deque<QueuedAction> actionQueue;
    std::unordered_map<uint64_t, std::vector<uint8_t>> contentQueue;
    
    void runActionThread();
    void updatePackageStatus(const std::vector<RaceHandle> &handles, PackageStatus status);
};

#endif
```

---

## 11. Debugging Tips

### 11.1 Enable Debug Logging

```cpp
// In component constructor or via environment
RaceLog::setLogLevelStdout(RaceLog::LL_DEBUG);
```

### 11.2 Common Failure Modes

| Symptom | Likely Cause |
|---------|--------------|
| Component stays in `INIT` state | User input handles not resolved, `ready` never set true |
| `LINK_DESTROYED` immediately after create | `preLinkCreate` failed (maxLinks exceeded, wrong role) |
| `onReceive` never called | Fetch not finding data, wrong address parsing, service auth failure |
| Build fails with missing symbols | Missing source files in `setup_component_target` SOURCES |
| Plugin not loaded | Manifest `shared_library_path` doesn't match built `.so` name |

### 11.3 Inspecting Link Addresses

```bash
# Link addresses are JSON strings passed via --send-address and --recv-address
# Example Skyhook address:
{"region":"eu-west-2","fetchBucket":"bucket","initialFetchObjUuid":"uuid1","postBucket":"bucket","initialPostObjUuid":"uuid2","maxTries":5,"openObjects":1,"singleReceive":true}
```

---

## 12. Agent Workflow Commands

### Build and Test Loop

```bash
# 1. Make code changes
# 2. Rebuild
cd /home/ubuntu/racegen/code/my-plugin
./build_artifacts_in_docker_image.sh -l -v latest

# 3. Run unit tests (inside builder container)
cd build && ctest --output-on-failure

# 4. Copy artifacts to kits for integration test
cp -r kit/artifacts/linux-x86_64-*/PluginMyPlugin /path/to/raceboat/kits/

# 5. Run integration test (see Section 6.1)
```

### Code Quality Checks

```bash
# Format
make format

# Lint
make lint

# Static analysis
make cppcheck

# Coverage
make coverage
```

---

## Appendix: Key Type Definitions

```cpp
// From ComponentTypes.h
using LinkID = std::string;
using RaceHandle = uint64_t;
using Timestamp = double;  // Unix epoch seconds

enum ComponentStatus { COMPONENT_UNDEF, COMPONENT_OK, COMPONENT_ERROR, COMPONENT_FATAL };
enum ComponentState { COMPONENT_STATE_INIT, COMPONENT_STATE_STARTED, COMPONENT_STATE_FAILED };
enum LinkStatus { LINK_CREATED, LINK_LOADED, LINK_DESTROYED };
enum PackageStatus { PACKAGE_SENT, PACKAGE_FAILED_GENERIC, ... };
enum ActionType { ACTION_UNDEF, ACTION_FETCH, ACTION_POST };

struct Action {
    Timestamp timestamp;
    uint64_t actionId;
    std::string json;  // Contains linkId and type
};

struct EncodingParameters {
    LinkID linkId;
    std::string type;        // MIME type (e.g., "*/*")
    bool encodePackage;
    std::string json;        // Extra params for encoding
};

struct TransportProperties {
    std::unordered_map<std::string, std::vector<std::string>> supportedActions;
    // e.g., {"post": ["*/*"], "fetch": []}
};

struct LinkProperties {
    LinkID linkId;
    std::string linkAddress;  // JSON string of LinkAddress
    LinkType linkType;
    TransmissionType transmissionType;
    ConnectionType connectionType;
    SendType sendType;
    bool reliable;
    bool isFlushable;
    int duration_s;
    int period_s;
    int mtu;
    LinkPropertySet worst, expected, best;
    std::vector<std::string> supported_hints;
    std::string channelGid;
};
```

---

This guide should enable agents to efficiently implement Raceboat transport components following established patterns. Refer to the reference implementations in `code/skyhook/` and `code/decomposed-exemplars/` for concrete examples.