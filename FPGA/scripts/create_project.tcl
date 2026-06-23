create_project LIFNeuralNetwork ./LIFNeuralNetwork -part xczu3eg-sbva484-1-i

set_property target_language VHDL [current_project]
set_property enable_vhdl_2008 1 [current_project]

add_files -norecurse ./rtl/neuron_package.vhd
add_files -norecurse ./rtl/control_layer.vhd
add_files -norecurse ./rtl/datapath_layer.vhd
add_files -norecurse ./rtl/weight_unit.vhd
add_files -norecurse ./rtl/memory.vhd
add_files -norecurse ./rtl/control_neuron.vhd
add_files -norecurse ./rtl/datapath_neuron.vhd
add_files -norecurse ./rtl/lif_layer.vhd
add_files -norecurse ./rtl/lif_neuron.vhd
add_files -norecurse ./rtl/network_datapath.vhd
add_files -norecurse ./rtl/network_control.vhd
add_files -norecurse ./rtl/lif_network.vhd

set_property SOURCE_SET sources_1 [get_filesets sim_1]

add_files -fileset sim_1 -norecurse ./rtl/test_network.vhd
add_files -fileset sim_1 -norecurse ./memory/mem0.mem
add_files -fileset sim_1 -norecurse ./memory/mem1.mem


set_property file_type {VHDL 2008} [get_files *.vhd]

set_property top test_network [get_filesets sim_1]
set_property top lif_network  [get_filesets sources_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1