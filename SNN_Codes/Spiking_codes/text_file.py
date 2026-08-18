#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jan 24 15:35:28 2022

@author: nelson
"""

class text_files:
    """
    Handles the creation, loading, and writing of simulation data files.

    The class stores simulation data in CSV format. Each row contains
    an automatically generated ID followed by the values provided to
    :meth:`append_data`.

    Args:
        new_file (bool): If True, creates a new CSV file. If False,
            loads an existing file.
        file_name (str): Name of the CSV file without the extension.
        path (str): Base directory where the ``data_result`` directory
            is located.
        structure (list, optional): Names of the columns to be stored
            in the CSV file. Required when ``new_file`` is True.

    Attributes:
        path (str): Directory where the CSV file is stored.
        name (str): Complete path of the CSV file.
        ID (int): ID assigned to the next row of data.
        columns_names (list): Names of the data columns.
    """

    def __init__(self, new_file, file_name, path ,structure = ''):
        """
        Initialize the text file manager.

        Args:
            new_file (bool): Determines whether a new file should be
                created or an existing file should be loaded.
            file_name (str): Name of the CSV file without extension.
            path (str): Base directory for the ``data_result`` folder.
            structure (list, optional): Column names used when creating
                a new file.
        """
        self.path = path+'/data_result/'
        self.name = self.path+file_name+'.csv'
        self.ID = 0
        self.columns_names = []

        if new_file:
            self.columns_names = structure
            self.new_file()
        else:
            self.load_file()

            
    def new_file(self):
        """
        Create a new CSV file and write its header.

        The first column is an automatically generated ``ID`` column,
        followed by the names provided in ``columns_names``.
        """
        header = 'ID,' + ','.join(self.columns_names) + '\n'
        with open(self.name, 'w') as file:
            file.write(header)

        
    def load_file(self):
        """
        Load an existing CSV file.

        Reads the column names from the header and determines the ID
        that should be assigned to the next data row.
        """
        with open(self.name, 'r') as file:
            data = file.read().splitlines()

        self.columns_names = data[0].split(',')[1:]

        if len(data) > 1:
            value = data[-1].split(',')[0]
            self.ID = int(value) + 1
        else:
            self.ID = 0

    
    def append_data(self,data):
        """
        Append a new row of data to the CSV file.

        The row starts with the current ID value. After the row is written,
        the ID is incremented for the next row.

        Args:
            data (list): Values to append to the CSV file.
        """        
        str_data = str(self.ID) + ',' + ','.join(str(value) for value in data) + '\n'
        with open(self.name, 'a') as file:
            file.write(str_data)
        self.ID += 1


    def is_created(self):
        """
        Check whether the CSV file exists.

        Returns:
            bool: True if the file exists, otherwise False.
        """
        try:
            with open(self.name, 'r'):
                return True
        except FileNotFoundError:
            return False 
