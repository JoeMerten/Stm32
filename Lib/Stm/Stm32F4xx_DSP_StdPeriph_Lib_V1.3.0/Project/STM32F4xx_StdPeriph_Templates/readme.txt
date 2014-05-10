/**
  @page Template  <Example brief description (1 line)>
  
  @verbatim
  ******************** (C) COPYRIGHT 2013 STMicroelectronics *******************
  * @file    Project/STM32F4xx_StdPeriph_Templates/readme.txt 
  * @author  MCD Application Team
  * @version V1.3.0
  * @date    13-November-2013
  * @brief   Description of the TEMPLATE example
  ******************************************************************************
  *
  * Licensed under MCD-ST Liberty SW License Agreement V2, (the "License");
  * You may not use this file except in compliance with the License.
  * You may obtain a copy of the License at:
  *
  *        http://www.st.com/software_license_agreement_liberty_v2
  *
  * Unless required by applicable law or agreed to in writing, software 
  * distributed under the License is distributed on an "AS IS" BASIS, 
  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  * See the License for the specific language governing permissions and
  * limitations under the Licens
  *   
  ******************************************************************************
  @endverbatim

@par Example Description

This example is used as a template project that can be used as reference to build
any new firmware application for STM32F405xx/407xx, STM32F415xx/417xx, STM32F427xx/437xx 
or STM32F429xx/439xx devices using the STM32F4xx Standard Peripherals Library.


@par Directory contents
  
  - Template/system_stm32f4xx.c   STM32F4xx system clock configuration file
  - Template/stm32f4xx_conf.h     Library Configuration file
  - Template/stm32f4xx_it.c       Interrupt handlers
  - Template/stm32f4xx_it.h       Interrupt handlers header file
  - Template/main.c               Main program
  - Template/main.h               Main program header file


@par Hardware and Software environment

  - This example runs on STM32F405xx/407xx, STM32F415xx/417xx, STM32F427xx/437xx and 
    STM32F429xx/439xx devices.
  
  - This example has been tested with STMicroelectronics STM324xG-EVAL (STM32F40xx/
    STM32F41xx Devices), STM32437I-EVAL (STM32F427xx/STM32F437xx Devices) and 
    STM324x9I-EVAL RevB (STM32F429xx/STM32F439xx Devices) evaluation boards and 
    can be easily tailored to any other supported device and development board.


@par How to use it ? 

In order to make the program work, you must do the following:
 + EWARM
    - Open the Template.eww workspace 
    - Rebuild all files: Project->Rebuild all
    - Load project image: Project->Debug
    - Run program: Debug->Go(F5)
 
 + MDK-ARM
    - Open the Template.uvproj project
    - Rebuild all files: Project->Rebuild all target files
    - Load project image: Debug->Start/Stop Debug Session
    - Run program: Debug->Run (F5) 
    
 + TrueSTUDIO
    - Open the TrueSTUDIO toolchain.
    - Click on File->Switch Workspace->Other and browse to TrueSTUDIO workspace directory.
    - Click on File->Import, select General->'Existing Projects into Workspace' and then click "Next". 
    - Browse to the TrueSTUDIO workspace directory, select the project.
    - Rebuild all project files: Select the project in the "Project explorer" 
      window then click on Project->build project menu.
    - Run program: Run->Debug (F11)
 
 + Ride   
    - Open the Project.rprj project.                          
    - Rebuild all files: Project->build project
    - Load project image: Debug->start(ctrl+D)
    - Run program: Debug->Run(ctrl+F9)  
              
 * <h3><center>&copy; COPYRIGHT STMicroelectronics</center></h3>
 */
 