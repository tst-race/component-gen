# RACEGEN

We are implementing a new indirect transport mechanism for the raceboat framework.

- Indirect meaning it will provide communication between two copies of itself running on separate network nodes by moving data through a third-party service.

- Transport meaning it will implement the Transport Component API of the raceboat framework. There are several existing example implementations of this.

- The new mechanism needs to specify what types of content are suitable. For example, a cloud storage channel can store arbitrary binary data, while a social media service can likely only store base64-encoded data or various types of media files.  If there different transport actions necessary for these different content types, those need to be specified.

- This prompt will be provided with a seed service idea, the implementation will flow from that in sequence of steps:

## 1. High-level Design

First the service will be assessed for potential use. Critical components include:

1. The ability to store data with the third-party service in such a way that someone else, either with the same, different, or NO credentials can be given access to read that stored data.

2. The ability to "address" data stored in the third-party service to someone else, such that they can efficiently retrieve it. This can involve some overhead: for example, posting images to a social media service using a popular hashtag could impose the need for the recipient to download many irrelevant images on the same hashtag.

3. The ability to automate interactions with the service either via published APIs or via REST or HTTP based APIs that can be used programmatically despite being intended for direct human user interactions. Identify whether API tokens of some kind are needed.

This step should generate a markdown file containing the assessment and precise definitions of each potential method of addressing and each potential type of data content that could be stored. This file should sort and annotate these alternatives according to how innocuous they will appear to an adversary who could be another user, a network observer, or the service itself.

## 2. Precise Design

Now take the most highly-rated notional design from the high level design report markdown and expand it to a precise definition of the channel. This definition should include the following sections:

1. A precise description of what sort of authentication credentials are necessary for senders and receivers
2. Whether data uploaded is visible to all users or only users with specific credentials on the service
3. What types of data/content are suitable for innocuous storage and retrieval on the service. List the types paired with a name for the type of action to the service is used to store and retrieve that content.
4. Whether the channel will inherently support bidirectional communication or whether that bidirectionality will be accomplished by creating two independent unidirectional channel instances.
5. Whether the channel will inherently support efficient multicast or is unicast.
6. How long stored data will be accessible to be retrieved.
7. Whether stored data can be deleted after retrieval without creating suspicious service usage.

## 3. Service Interaction Implementation

Building on the precise design markdown, create an initial service interaction markdown design that identifies precisely which actions will need to be used and the path for executing those actions programmatically. Create stub code for these interactions that can support initial independent tests that the actions by themselves work. Write these "unit tests" for the interaction with support for ingesting whatever credentials or API tokens are necessary (if any).

Request the necessary information and then run these tests. Iterate code creation and testing until the unit tests demonstrate the ability to execute the desired actions on the service. The result of success should provide proof of concept of using the service to transport a small amount of arbitrary data in some reasonable content form. Encoding the data into that form is not within the scope of these tests and appropriate form of content example should be prompted for if it cannot be automatically generated.

## 4. Raceboat transport component implementation

Take the precise design markdown and the stub service interaction code and implement a raceboat compliant transport component. Use existing implementations of transport components for redis, mastodon, and AWS S3 as model implementations. Use the stub service code for applicable interactons. Notable functionalities:

1. Ingestion of parameters via requestUserInput APIs
2. Inclusion of encoded content queued for storing via EnqueueData
3. Management of multiple links and proper handling of addresses (creating and loading them) to support multiple simultaneous connections.
4. Use of the User Model action generation system to specify when actions are performed (outside the scope of the transport component to schedule those actions).
5. Construction of the integration test components to run automated integration tests.

In addition to the implementation, a design document should be generated detailing overall functionality, security concerns, and nuances of use.

A Component Integration markdown document must be generated that specifies two critical pieces of interaction:

1. For the User Model interaction, precisely describe the types of actions that can be used, the types of content they need to function, and any events the transport emits for the user model to understand.

2. For the Encoding intreaction, precisely describe the types of content that can be used and any additional parameters they will have (e.g. if an image, what type of image formats are OK and what sizes etc.).

### Build and Test
The new transport component should be compiled and its integration tests run to completion. Any out-of-scope parameters (e.g. user credentials) should be prompted for from the developer or pulled from the prior stub tests.

Build and test errors should be investigated and fixed and rerun until the build and tests pass or an error appears insurmountable.