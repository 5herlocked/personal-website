# Bringing Bedrock's Model Choice to Minimalist Engineers

_A quick story on integrating Bedrock with the Zed IDE and all the ways Rust made it amazing and a little painful._

"It can't be that difficult, surely."

I remember saying that in November 2024, when I started working on the Bedrock integration for the Zed IDE. My interest in Zed came primarily from the fact that they built it from scratch in Rust, and not only the backend, but even the UI. A truly exceptional feat of engineering that warranted the creation of a new cross-platform UI framework that compiles down to native for each of the supported platforms (macOS, Windows, Linux).

But 6 months of work, nearly 1,600 lines of code, and several keyboards later, you can chat with 39 serverless models in Bedrock through Zed. I learnt a lot; about Rust, about Bedrock, and about IDEs. With this article I'll share some of these learnings with you.

## ConverseStream is an awesome API

For a chat focused experience, ConverseStream provides a great starting point to architect your system around. It gives you a concrete representation of what messages can look like, has the building blocks to provide Tool Use and can effectively connect to MCP servers.

For me and with Zed all it meant was writing a transformation function that converted from Bedrock Messages to Zed LanguageModelEvents and vice versa. The Rust compiler accelerated this process by being very strict with the match control flow, so much that the transformation layer only took two proper attempts, largely written by Amazon Q Developer.

Since this API also supported Claude 3.7 Sonnet Thinking as soon as it came out, it was rather trivial to add two cases for the ReasoningContent response classes and Zed very quickly had support for Hybrid reasoning models!

## Cross-Region inference

While implementing cross region inference can be a little tedious, it effectively increases your TPM by up to three times, making it a worthwhile investment for customers and partners who aren't latency sensitive but still constrained by real-time interactions.

With tool use interactions being token and request intensive, this is useful since a multi-turn tool use interaction can exceed the TPM or RPM limits in one region.

In Zed, I entirely derive this from the region that the user chooses, and instead of building a fancy data structure that stores which model is available in what region. We use our trusted friend match and just update it as necessary when AWS adds new models to the Bedrock catalog.

The long term the solution is to populate the Zed UI with the models that the user has access to by calling the Bedrock control plane and getting all the information from there.

## Streaming data is hard

I'm sure anyone who has worked with Streaming Data in the past can sympathize; it's made particularly infuriating and functional by Rust. One of the lesser known but powerful features of Rust is lifetimes. It essentially let's the Rust compiler know how long a particular piece of data/memory is relevant and when to get rid of it.

What that means for streams is that every operation needs to know how long the stream is going to be alive and in our case since the stream is retrieved from the API, from the app's perspective that stream lives forever (`'static` for the rustaceans out there). It also means we have to do a lot of async move and await magic to make the streaming look and behave "normal". My journey of wrestling with streaming data is entirely documented in [this PR](https://github.com/zed-industries/zed/pull/123) which fixes bedrock streaming and fundamentally involved rewriting and simplifying how I worked with the stream, tokio, and a custom http client specifically for all AWS interactions.

## Amazon Nova models are interesting

This is entirely a personal observation but the Nova family of models is pretty good at coding and being able to use it through Zed for a bevy of code generation tasks makes it an interesting proposition from a cost to performance perspective. I like to use Nova Pro and Claude 3.7 Sonnet Thinking for all the Agentic editing experiences, while for inline assistance, i like to use Nova Micro for it's lightning fast and accurate responses.

Right now, Nova is available through Zed and Bedrock as a fully supported model family and I have already used it to rapidly translate TypeScript into Go very quickly with very few changes fundamentally required to the code after translation -- only time will tell how good Nova Pro can be when provided with the right knowledge base.

Working with Zed has been an incredibly informative experience for what goes into making a great IDE and I intend to continue supporting Zed and Bedrock for as long as I can.

See you next time reader,
Shardul

---

_Published: April 10, 2025_
_Originally published on [AWS Builder Center](https://community.aws)_
