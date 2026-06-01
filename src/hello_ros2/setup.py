from setuptools import find_packages, setup

package_name = 'hello_ros2'

setup(
    name=package_name,
    version='0.1.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='user',
    maintainer_email='user@example.com',
    description='Minimal ROS2 example',
    license='Apache-2.0',
    entry_points={
        'console_scripts': [
            'publisher = hello_ros2.publisher:main',
            'subscriber = hello_ros2.subscriber:main',
            'marker_publisher = hello_ros2.marker_publisher:main',
        ],
    },
)
