![Thecore Logo](https://github.com/gabrieletassoni/thecore/raw/master/app/assets/images/logo.png)
# Thecore
**Thecore** is made of _ATOMS_ or, well, **Atomic Components**. 
The RoR App, the one made using _rails new_ command, will become just a container dependent on the _Atomic Components_ you need.
**Thecore** is a set of tools, best practices and guidelines aimed at creating bigger WebApps without focusing on how to do it.

**It's way better to focus on what to do, don't you think?**

## But... _What are ATOMS?_
 * **Self Contained engines:** the _Atomic Component_ must be developed following some guidelines which I'll document in the [Wiki](https://github.com/gabrieletassoni/thecore/wiki/Atomic_Component_Guidelines).
 * **Pluggable Components:** just make your RoR WebApp or another _Atomic Component_ depend on an _Atomic Component_ and it will inherit the funcitonalities of the _Atomic Component_, you don't need them anymore? just remove the dependency from Gemfile or gemspec and your WebApp will continue to work as before, but without the functionality provided by the _Atomic Component_
 * **Tested Components:** once tested for one application, they are tested for every other applications, no need to do regression tests on your app if it includes (say... depends) on functionalities provided by an Atomic Component.
 * **Easily Extandable:** _Atomic Components_ can be improved in their functionalities by adding new , but even better, they can be extended, without the need to touch well established code, in other _Atomic Components_ which will depend on the original one.
## Whys
As a freelance full-stack developer I always needed smart tools and methods to manage scalable projects. During the years I started to make choices, studying languages, patterns and technologies that were getting my attention because of their smartness.

Here is the efforts-turned-code, used and tested in different professional projects; thecore is just one of the  components, the most important, the foundation on which all the other atomic components grow. On github I'll put all of them, or, at least the general ones, the ones which doesn't have a strong characterization on a process peculiar to one of my customers.
## Philosphy
I always preferred to invest some more time in finding the best tool for what I need and compile a toolbox of helpful technologies, rather than start coding mindlessly. Thecore has grown and proved to be a time saver, it surely could be enhanced and as long as I keep using it for my day by day job, it will grow more, but if you feel that RoR, sane defaults, atomic engines (components) sound good to you, don't be scared to pull and make Thecore even more useful.
## Atomic Components
Here will be kept track of all the _Atomic Components_ available.
 * Utilities
    * [Thecore Thor Scripts](https://github.com/gabrieletassoni/thecore_thor_scripts): A set of scripts used to create new **Thecore** WebApps or new _Atomic Components_ and to transform an already created engine, into a **Thecore** _Atomic Component_
## Partecipate
If you like to partecipate on this project, please do so; file bugs, pull and modify code, give suggestions...
## Support
Hire [me](mailto:gabriele.tassoni@gmail.com) as a full-stack developer for your RoR projects, I will use Thecore technology and show you how good it is. This is a straightforward way to support this project.
## Wiki
In the [wiki](https://github.com/gabrieletassoni/thecore/wiki) I'll put all the useful articles needed to fully understand the tool and the background theory.
## TO DO
 * **Document guidelines:** **Thecore** and the _Atomic Components_ are best used if you follow some guidelines, good programming tips. Some of the guidelines will be automated by some _rails [plugin] new_ templates and thor scripts, some other are just a matter of embracing sane defaults and methods.
 * **Code Cleanup**: move some views and assets in a dedicated **Thecore** Component
 * **Embrace Yarn completely**: rewrite some JS assets as installable packages and move them in a dedicated component
 * **Build a builder:** a web applications build upon **Thecore** and _Atomic Components_ will be released to aid in the process of creating your own application, it will assist in the process of defining the RoR WebApp or the building of a new Atomic Component.
