/**
  @page mdkarm MDK-ARM Project Template for STM32F4xx devices
  
  @verbatim
  ******************** (C) COPYRIGHT 2013 STMicroelectronics *******************
  * @file    readme.txt
  * @author  MCD Application Team
  * @version V1.3.0
  * @date    13-November-2013
  * @brief   This sub-directory contains all the user-modifiable files needed to 
  *          create a new project linked with the STM32F4xx Standard Peripherals  
  *          Library and working with RealView Microcontroller Development Kit(MDK-ARM)
  *          software toolchain.
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
  * limitations under the License.
  *
  ******************************************************************************
  @endverbatim
 
@par Directory contents
 
 - Project.uvproj/.uvopt: A pre-configured project file with the provided library 
                          structure that produces an executable image with MDK-ARM.

 @note Enabling "Options for Target — Output – Browser Information" is useful for
       quick source files navigation but may slow the compilation time.                 
 
 
@par How to use it ?
 
 - Open the Project.uvproj project
 - In the workspace toolbar select the project config:
     - STM32F429_439xx: to configure the project for STM32F429xx/439xx devices.
     @note The needed define symbols for this config are already declared in the
           preprocessor section: USE_STM324x9I_EVAL, STM32F429_439xx, USE_STDPERIPH_DRIVER

    - STM32F427_437xx: to configure the project for STM32F427xx/437xx devices.
     @note The needed define symbols for this config are already declared in the
           preprocessor section: USE_STM324x7I_EVAL, STM32F427_437xx, USE_STDPERIPH_DRIVER
           
     - STM32F40_41xxx: to configure the project for STM32F40/41xxx devices.
     @note The needed define symbols for this config are already declared in the
           preprocessor section: USE_STM324xG_EVAL, STM32F40_41xxx, USE_STDPERIPH_DRIVER
           
     - STM32F401xx: to configure the project for STM32F401xx devices.
     @note The needed define symbols for this config are already declared in the
           preprocessor section: STM32F401xx, USE_STDPERIPH_DRIVER
           
 - Rebuild all files: Project->Rebuild all target files
 - Load project image: Debug->Start/Stop Debug Session
 - Run program: Debug->Run (F5)
    
 * <h3><center>&copy; COPYRIGHT STMicroelectronics</center></h3>
 */
