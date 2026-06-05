import rclpy
from rclpy.node import Node
from sensor_msgs.msg import JointState


class JointStatePub(Node):
    def __init__(self):
        super().__init__('xarm_joint_state_pub')
        self.pub = self.create_publisher(JointState, '/joint_states', 10)
        self.create_timer(0.1, self.publish)

    def publish(self):
        msg = JointState()
        msg.header.stamp = self.get_clock().now().to_msg()
        # Active joints only — mimic joints computed by robot_state_publisher
        msg.name = ['joint1', 'joint2', 'joint3', 'joint4', 'joint5', 'joint6', 'drive_joint']
        msg.position = [0.0, 0.0, 0.0, 0.0, -1.5707963, 0.0, 0.0]
        self.pub.publish(msg)


def main():
    rclpy.init()
    node = JointStatePub()
    rclpy.spin(node)
    rclpy.shutdown()
