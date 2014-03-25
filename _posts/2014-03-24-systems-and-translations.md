---
layout: post
title: "Systems and Translations"
description: "A reflection on the SysSon software layout and how it interacts with the Sound Processes computer music system."
# modified: 2014-03-24 21:09:52 +0100
author: sciss
# category: []
tags: []
image:
  feature: 
  credit: 
  creditlink: 
comments:
share: 
---

When I started to develop the [SysSon software](https://www.github.com/iem-projects/sysson) in the beginning of 2013, it was pretty much unclear of how the tool would look. The only given were the climate data sets from WegC which were stored in [NetCDF](http://www.unidata.ucar.edu/software/netcdf/) files. Given that my sound synthesis client ["ScalaCollider"](https://www.github.com/Sciss/ScalaCollider) was stable enough, the first quickly put together version consisted of a thin wrapping layer around the Java version of NetCDF and ScalaCollider.

In spring I went for a residency at the ZKM, and there part of the time I was working on a tape composition front-end ["Mellite"](https://github.com/Sciss/Mellite) for my framework ["Sound Processes"](https://github.com/Sciss/SoundProcesses) which is the major product that came out of my PhD. Having refined these two bits, naturally the infra-structure of Sound Processes gradually began to leak into the SysSon project, because it contained many modules which were useful and tested.

So there in an interesting convergence between this general computer music system and the SysSon software. Before describing how the two go together, I have drawn a small diagram which shows the different layers in a horizontal succession:

<figure>
  <a href="{{ site.url }}/images/sysson_translation.png"><img src="{{ site.url }}/images/sysson_translation.png"></a>
    <figcaption>Diagram showing the translation process from sonification model to sound synthesis objects. There are three system types involved, the persistent SysSon workspace, the ephemeral (in-memory only) Sound Processes representation, and the ephemeral sound server.</figcaption>
</figure>

Melitte does not formally appear in this diagram, but already a couple of GUI strategies in SysSon are actually derived from Melitte code, and as we are beginning to conceive the sound installation composition, I expect elements such as the timeline views to become useful.

## Interfacing

When combining software modules, you are always confronted with the question of interfacing. How does one piece fit together with the other. In the traditional OOP paradigm, you might want to subclass and extend a specific module. In FP, you might want to work with type classes. Scala itself introduces the "cake pattern", etc. Sound Processes is special since it is based on a system abstraction layer called [Lucre STM](https://github.com/Sciss/LucreSTM). It uses the model of data structures composed of mutable cells, and these cells are parametrised with a system type. This system determines whether the data structure is made durable (stored on hard-disk) or only kept in memory. The second distinction is between persistence, which may be either confluent (the history of the data structure modifications is preserved) or ephemeral (the history is not preserved; if a datum is changed, its previous value is forgotten). All this complicates the matter of playing standard programming technique patterns, because we are not dealing any more with the plain and unconstrained data and GC memory model of the JVM. 

Lucre STM, as the name suggests, uses a software transactional memory (STM) as its main abstraction. Because data cells are potentially made durable, there is the need to provide serialisation of types (cells). Serialisation is currently done by providing static compile-time checked serialisers (little pieces of code that say how the data is organised) which must be hand-written but which can be composed or assembled. This works nicely with sum types (dijoint unions) such as Scala's sealed traits. But it poses a problem for extending an existing system, a scenario which we encounter here with SysSon. For example, there is a type `Proc` (for process) which encapsulates a synth graph function, an open-ended dictionary (map) and an interface for signals called `Scans`. But extending the interface of `Proc` is currently difficult---because we wouldn't have one statically know serial format---although I am thinking about a new iteration of Lucre STM which simplifies black-box type of serialization.

Therefore, the notion of _re-writing_ is a straight forward alternative to solve the modularity problem. Instances of translations are indicated by dotted arrows in the diagram. Instead of extending `Proc` and storing it durable with the SysSon workspaces, a new type `Sonification` is introduced containing all the pieces we need in SysSon. In order to make use of the Sound Processes framework, we need to _translate_ these sonfication models into sound process objects. The sonification's sound model is specified by a `SynthGraph`, a ScalaCollider description of interconnected UGens, so it can be directly copied into the `Proc` instance. A fast and efficient way of serialising arbitrary Scala functions is not yet available---although I have made some experiments which point into that direction---and so synth graphs are not just compiled, but when "executed" they actually yield a tree structure of objects which _can_ be easily serialised. A synth graph is a sort of "syntax tree" within the object language, that is to say. Any functionality added by SysSon in terms of the sound description model is implemented as such building blocks of type `GE` (for "graph element"). These are only "expanded" (you could say, "interpreted") when the sound production is really initiated.

As an example, `UserValue(<key>, <default>)` _declares_ a controller to be shown in the SysSon GUI as a generic parametrisation means. From the Sound Processes perspective, however, we have an interface to a `Proc`'s attribute map, and so during the translation from SysSon to Sound Processes, the user values are translated from the sonification structure into the attribute map. Likewise, Sound Processes has no notion of NetCDF files but only of audio file based artifacts (a type of _grapheme_, where grapheme generally is a time-based object to which we have random access). So there is a mechanism which translates the sonification's data sources, matrices or transformed matrices, into cached audio files which can then be part of a process' attribute map again.

## Ephemeral Sound Processes

As can be seen in the diagram, I decided to use Sound Processes with an ephemeral (and in fact in-memory) system. It means that the translations are made "on the fly" and their results are not stored as part of the SysSon workspace. The workspace, on the other hand, currently uses an ephemeral but durable system. It means that all the parametrisations of the sonfications are remembered, although their evolution or history is not. Once we want to observe the system's evolution, for example to trace how the users at WegC are interacting with the software during our training and testing sessions, but also perhaps during the sound installation, we can create workspaces which are confluently persistent, so they would store the parameter evolutions as well.

The translation is _triggered_ through an instance of `AuralSonification`. Like Sound Processes, which distinguishes between a `Proc` "model" and an `AuralProc` "view", this again produces an MVC kind of separation of functions. The `Sonification` type is not concerned with the interaction with a real-time sound system, it is more like a plain data structure. On the other hand, the aural sonification is an observation instance ("view") which produces the auxiliary structures needed for the real-time sound synthesis. In this special case, the view indeed acts as another _model_ (a `Proc` placed on an invisible timeline, the `ProcGroup`, set into motion through a `Transport`). This secondary model is picked up by the Sound Processes aural system which has its own "view" called `AuralPresentation`.

Although I like very much the idea of cascaded re-writing systems---it is both poetically beautiful and coherent with my idea of what the so-called "represenation" in sonification implies---I have come to think now that the further integration with the whole Melitte toolbox would benefit from an approach which does not treat the `Proc` instances as throw-away objects, but makes them full citizens inside the SysSon workspace. It we make `Proc` more extensible, then `Sonification` could actually "mix in" the `Proc` trait and extend it in the ways we need for SysSon. Melitte, in turn, would benefit from our efforts to formalise elements which require caching and offline calculation, as is the case with the translation of data matrices to audio files. From the diagram it is obvious that the left layer begins to duplicate the functionality of the middle layer. Uniting the two would produce a synergetic effect.

The price is the effort to do the necessary refactoring in Sound Processes, and also making the projects depend closer on each other means that there will be more cycles where snapshots of the latter must be recompiled, published and re-pulled into the former, something that can get quite annoying.

