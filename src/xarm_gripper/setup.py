from setuptools import setup
from glob import glob

package_name = 'xarm_gripper'

setup(
    name=package_name,
    version='0.1.0',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/xarm_gripper']),
        ('share/' + package_name, ['package.xml']),
        ('share/' + package_name + '/meshes', glob('meshes/*.STL')),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='rustam',
    maintainer_email='ywspeakdb@gmail.com',
    description='xArm parallel gripper mesh files',
    license='BSD',
    entry_points={},
)
