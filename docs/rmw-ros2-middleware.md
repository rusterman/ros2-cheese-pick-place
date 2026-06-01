The ROS 2 middleware (often abbreviated as RMW) is the underlying software layer that handles the transport, serialization, and discovery of messages between different parts of a robotic system. It serves as an abstraction layer between the [ROS 2 Client Libraries (RCL)](0.5.3, 0.5.7) and the underlying network protocol. [1, 2, 3, 4]  
How the Middleware Works 
Instead of using a custom communication protocol (like in ROS 1), ROS 2 delegates its core networking to industrial-grade communication standards like DDS (Data Distribution Service) or Zenoh. [1, 3, 5]  
The middleware handles three primary jobs: 

1. Discovery: Automatically locating other active nodes, sensors, and actuators on the network without requiring a centralized master. 
2. Serialization: Translating code objects into a transmittable byte stream (and vice versa). 
3. Transportation: Delivering data packets using publish/subscribe or client/server paradigms. [1, 2, 3, 4, 6, 7]  

Supported Middleware Implementations 
Because robotic applications have varying demands (e.g., real-time constraints, resource-constrained edge devices, or corporate licensing), ROS 2 allows you to swap out the middleware vendor via an environment variable (). [1, 3, 4, 8, 9]  
Commonly used RMW implementations include: 

• Eclipse Cyclone DDS: A highly performant, lightweight, and open-source DDS default in many ROS 2 distributions. 
• eProsima Fast DDS: Another widely used open-source DDS implementation and former default in ROS 2. 
• RTI Connext DDS: A proprietary, enterprise-grade DDS option used in safety-critical and high-reliability commercial systems. 
• Zenoh: A newer, internet-scale protocol and RMW alternative to DDS that is highly optimized for challenging network conditions and edge computing. [3, 4, 8, 10, 11]  

The RMW Interface 
To keep ROS 2 applications independent of the underlying network, the system relies on the ROS Middleware Interface (RMW). This API layer defines exactly how the higher-level ROS 2 Client Libraries (such as  or ) talk to the chosen middleware. 

• Benefits: This architecture allows developers to switch between different DDS vendors without rewriting their robotics algorithms or changing their source code. 
• Details: You can dive deeper into the technical architecture through the official ROS 2 Middleware Interface or review the About ROS 2 middleware implementations concept guides. [1, 10]  

