create_project LIFNeuralNetwork ./LIFNeuralNetwork -part xczu3eg-sbva484-1-i

set_property target_language VHDL [current_project]
set_property enable_vhdl_2008 1 [current_project]

add_files ./rtl/neuron_package.vhd
add_files ./rtl/weight_unit.vhd
add_files ./rtl/control_neuron.vhd
add_files ./rtl/datapath_neuron.vhd
add_files ./rtl/lif_neuron.vhd
add_files ./rtl/test_neuron.vhd

set_property file_type {VHDL 2008} [get_files *.vhd]

set_property top test_neuron [current_fileset]

update_compile_order -fileset sources_1